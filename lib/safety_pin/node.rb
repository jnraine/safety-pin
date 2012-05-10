module SafetyPin
  class Node
    include_class 'javax.jcr.PropertyType'
    include_class 'java.util.Calendar'
    include_class 'java.util.Date'

    attr_reader :j_node
    
    def self.find(path)
      raise ArgumentError unless path.to_s.start_with?("/")
      Node.new(session.get_node(path.to_s))
    rescue javax.jcr.PathNotFoundException
      nil
    end
    
    def self.session
      JCR.session
    end
    
    def self.build(path, node_type = nil)
      node_type ||= "nt:unstructured"
      rel_path = nil
      if path.start_with?("/")
        rel_path = path.sub("/","")
      else
        raise ArgumentError.new("Given path not absolute: #{path}")
      end
      
      if session.root_node.has_node(rel_path)
        raise NodeError.new("Node already exists at path: #{path}")
      else
        self.new(session.root_node.add_node(rel_path, node_type))
      end
    rescue javax.jcr.PathNotFoundException => e
      raise NodeError.new("Cannot add a new node to a non-existing parent at #{path}")
    end
    
    def self.create(path, node_type = nil)
      node = self.build(path, node_type)
      node.save
      node
    end

    def initialize(j_node)
      @j_node = j_node
    end
    
    def path
      @path ||= j_node.path
    end
    
    def session
      @session ||= JCR.session
    end
    
    def children
      child_nodes = []
      j_node.get_nodes.each do |child_j_node|
        child_nodes << Node.new(child_j_node)
      end
      child_nodes
    end
    
    def child(relative_path)
      child_j_node = j_node.get_node(relative_path)
      Node.new(child_j_node)
    rescue javax.jcr.PathNotFoundException
      nil
    end
    
    def name
      @name ||= j_node.name
    end
    
    def read_attribute(name)
      property = j_node.get_property(name)
      if property_is_multi_valued?(property)
        retrieve_property_multi_value(property)
      else
        retrieve_property_value(property)
      end
    rescue javax.jcr.PathNotFoundException
      raise NilPropertyError.new("#{name} property not found on node")
    end
    
    def property_is_multi_valued?(property)
      property.values
      true
    rescue javax.jcr.ValueFormatException
      false
    end
    
    def retrieve_property_multi_value(property)
      property.values.map {|value| retrieve_value(value) }
    end
    
    def retrieve_property_value(property)
      retrieve_value(property.value)
    end
    
    def retrieve_value(value)
      property_type = PropertyType.name_from_value(value.type)
      case property_type
      when "String"
        value.string
      when "Boolean"
        value.boolean
      when "Double"
        value.double
      when "Long"
        value.long
      when "Date"
        Time.at(value.date.time.time / 1000)
      when "Name"
        value.string # Not sure if these should be handled differently
      else
        raise PropertyTypeError.new("Unknown property type: #{property_type}")
      end
    end
    
    def write_attribute(name, value)
      raise PropertyError.new("Illegal operation: cannot change jcr:primaryType property") if name == "jcr:primaryType"
      
      if value.is_a? Array
        values = value
        val_fact = value_factory
        j_values = []
        values.each do |value|
          j_values << val_fact.create_value(value.to_java)
        end
        j_node.set_property(name, j_values.to_java(Java::JavaxJcr::Value))
      elsif value.is_a? Time or value.is_a? Date
        calendar_value = Calendar.instance
        calendar_value.set_time(value.to_java)
        j_node.set_property(name, calendar_value)
      else
        j_node.set_property(name, value)
      end
    end
    
    def save
      if new?
        j_node.parent.save
      else
        j_node.save
      end
      
      not changed?
    end
    
    def reload
      j_node.refresh(false)
    end
    
    def [](name)
      read_attribute(name)
    end
    
    def []=(name, value)
      write_attribute(name, value)
    end
    
    def changed?
      j_node.modified?
    end
    
    def new?
      j_node.new?
    end
    
    def properties
      props = {}
      prop_iter = j_node.properties
      while prop_iter.has_next
        prop = prop_iter.next_property        
        unless prop.definition.protected?
          prop_name = prop.name
          props[prop_name] = self[prop_name]
        end
      end
      props
    end
    
    def protected_properties
      props = {}
      prop_iter = j_node.properties
      while prop_iter.has_next
        prop = prop_iter.next_property        
        if prop.definition.protected?
          prop_name = prop.name
          props[prop_name] = self[prop_name]
        end
      end
      props
    end
    
    def properties=(new_props)
      # props.each do |name, value|
      #   self[name] = value
      # end
      property_names = (properties.keys + new_props.keys).uniq
      property_names.each do |name|
        self[name] = new_props[name]
      end
    end
    
    def value_factory
      session.value_factory
    end
    
    def destroy
      path = self.path
      parent_j_node = j_node.parent
      j_node.remove
      parent_j_node.save
      # raise NodeError.new("Unable to destroy #{path} node") unless self.class.find(path).nil?
    rescue javax.jcr.RepositoryException => e
      raise NodeError.new("Unable to destroy #{path} node: #{e.message}")
    end
    
    def mixin_types
      j_node.mixin_node_types.map(&:name)
    end
    
    def add_mixin(mixin_name)
      j_node.add_mixin(mixin_name)
    end
    
    def remove_mixin(mixin_name)
      j_node.remove_mixin(mixin_name)
    end
    
    def primary_type
      self["jcr:primaryType"]
    end
  end
  
  class NodeError < Exception; end
  class PropertyTypeError < Exception; end
  class NilPropertyError < Exception; end
  class PropertyError < Exception; end
end
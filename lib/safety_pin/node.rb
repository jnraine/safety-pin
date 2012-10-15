require 'pathname'

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
    
    def self.find_or_create(path, primary_type = nil)
      node_blueprint = NodeBlueprint.new(:path => path.to_s, :primary_type => primary_type)
      find(path) || create(node_blueprint)
    end

    def self.exists?(path)
      find(path) != nil
    end
    
    def self.session
      JCR.session
    end
    
    def self.build(node_blueprint)
      raise NodeError.new("NodeBlueprint is nil") if node_blueprint.nil?
      raise NodeError.new("NodeBlueprint has non-absolute path") unless node_blueprint.path.to_s.start_with?("/")
      raise NodeError.new("Node already exists at path: #{node_blueprint.path}") if Node.exists?(node_blueprint.path)
      
      rel_path_to_root_node = node_blueprint.path.to_s[1..-1]
      node = self.new(session.root_node.add_node(rel_path_to_root_node, node_blueprint.primary_type))
      node.properties = node_blueprint.properties

      node
    rescue javax.jcr.PathNotFoundException => e
      raise NodeError.new("Cannot add a new node to a non-existing parent at #{node_blueprint.path}")
    end

    def self.update(node_blueprint)
      node = find(node_blueprint.path)
      # raise NodeError.new("Cannot retrieve node for update -- might not exist") if node.nil?
      node.properties = node_blueprint.properties
      node.primary_type = node_blueprint.primary_type
      node.save
      node
    end
    
    def self.create(node_blueprint)
      node = self.build(node_blueprint)
      node.save
      node
    end

    def self.create_parents(path)
      intermediate_paths = []

      current_intermediate_path = Pathname(path)
      while(current_intermediate_path.to_s != "/")
        current_intermediate_path = current_intermediate_path.parent
        intermediate_paths.push(current_intermediate_path)
      end
      
      results = intermediate_paths.reverse.map do |intermediate_path|
        create(NodeBlueprint.new(:path => intermediate_path.to_s)) unless exists?(intermediate_path)
      end

      session.save

      results
    end

    def self.create_or_update(node_blueprint_or_node_blueprints)
      node_blueprints = Array(node_blueprint_or_node_blueprints)
      node_blueprints.map do |node_blueprint|
        if exists?(node_blueprint.path)
          update(node_blueprint)
        else
          create(node_blueprint)
        end
      end
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
      child_j_node = j_node.get_node(relative_path.to_s)
      Node.new(child_j_node)
    rescue javax.jcr.PathNotFoundException
      nil
    end
    
    def name
      @name ||= j_node.name
    end
    
    def read_attribute(name)
      name = name.to_s
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
      name = name.to_s
      
      if value.nil? and not j_node.has_property(name)
        return nil
      end
      
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
      elsif value.is_a? Symbol
        j_node.set_property(name, value.to_s)
      else
        begin
          j_node.set_property(name, value)
        rescue NameError
          raise SafetyPin::PropertyTypeError.new("Property value type of #{value.class} is unsupported")
        end
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
      property_names = (properties.keys + new_props.keys).uniq
      property_names.each do |name|
        # REFACTOR ME PLZ
        child_path = Pathname(path.to_s) + name.to_s
        if new_props[name].is_a? Hash
          new_props[name] = convert_hash_to_node_blueprint(new_props[name])
        end

        if new_props[name].respond_to?(:node_blueprint?) and new_props[name].node_blueprint?
          # Handle node blue prints
          node_blueprint = NodeBlueprint.new(:properties => new_props[name].properties, 
                                             :path => child_path.to_s, 
                                             :primary_type => new_props[name].primary_type)
          if Node.exists?(child_path)
            Node.update(node_blueprint)
          else
            Node.build(node_blueprint)
          end
        else
          # handle everything else
          self[name] = new_props[name]
        end
      end
    end

    # Convert a hash (and it's values recursively) to NodeBlueprints. This is a
    # helper method, allowing a hash to be passed in to Node#properties= when
    # only properties need to be set. One caveat: all node types will default
    # to nt:unstructured.
    def convert_hash_to_node_blueprint(hash)
      hash.keys.each do |key|
        if hash[key].is_a? Hash
          hash[key] = convert_hash_to_node_blueprint(hash[key])
        end
      end
      NodeBlueprint.new(:path => :no_path, :properties => hash)
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

    def primary_type=(primary_type)
      j_node.set_primary_type(primary_type)
    end
    
    def find_or_create(name, primary_type = nil)
      path = Pathname(self.path) + name
      self.class.find_or_create(path.to_s, primary_type)
    end
    
    # Create and return a child node with a given name
    def create(name, node_blueprint = nil)
      Node.create(node_blueprint_for(name, node_blueprint))
    end

    def build(name, node_blueprint = nil)
      Node.build(node_blueprint_for(name, node_blueprint))
    end

    def node_blueprint_for(name, node_blueprint = nil)
      path = Pathname(self.path) + name.to_s
      
      unless node_blueprint.nil?
        properties = node_blueprint.properties
        primary_type = node_blueprint.primary_type
      end
      
      NodeBlueprint.new(:path => path.to_s, :properties => properties, :primary_type => primary_type)
    end
  end
  
  class NodeError < Exception; end
  class PropertyTypeError < Exception; end
  class NilPropertyError < Exception; end
  class PropertyError < Exception; end
end
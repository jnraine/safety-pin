require 'rubygems'
require 'ripl'
require 'java'

class JCR
  include_class('java.lang.String') {|package,name| "J#{name}" }
  include_class 'javax.jcr.Repository'
  include_class 'javax.jcr.SimpleCredentials'
  include_class 'org.apache.jackrabbit.rmi.client.ClientRepositoryFactory'
  include_class 'org.apache.jackrabbit.commons.JcrUtils'

  attr_reader :repository, :creds, :session, :repository_name, :username

  def initialize(opts = {})
    @repository = JcrUtils.get_repository(opts[:hostname])
    @creds = SimpleCredentials.new(opts[:username], JString.new(opts[:password]).to_char_array)
    @session = @repository.login(creds)
    @repository_name = @repository.get_descriptor(Repository::REP_NAME_DESC);
    @username = @session.get_user_id
  end
end

module Wrappers
  class Property
    include_class 'javax.jcr.PropertyType'
    
    attr_reader :jcr_property, :value, :values, :type, :name
    
    def initialize(jcr_property)
      @jcr_property = jcr_property
      @name = jcr_property.name
      @type = PropertyType.name_from_value(type)
      if jcr_property.multiple_values?
        @values = jcr_property.values.to_a
      else
        @value = jcr_property.value
      end
    end
    
    def value
      jcr_property.value
    end
  end
end

JavaUtilities.extend_proxy("javax.jcr.Property") do
  def multiple_values?
    definition.multiple?
  end
end

JavaUtilities.extend_proxy("javax.jcr.Node") do
  def children
    child_node_iter = self.nodes
    child_nodes = []
    while child_node_iter.has_next
      child_nodes << child_node_iter.next_node
    end
    child_nodes
  end
  
  def properties_nice
    property_iter = self.properties
    properties = {}
    while property_iter.has_next
      property = Wrappers::Property.new(property_iter.next_property)
      properties[property.name] = property
    end
    properties
  end
  
  def inspect
    "<#{self.class} #{path}>"
  end
end

# class JavaClassWrapper
#   def initialize(instance)
#     @instance = instance
#   end
#   
#   def rubyify_getters
#     get_methods = methods.delete_if { |name| name.match(/^get\_/).nil? }
#     get_methods.each do |method_name|
#       rubified_method_name = method_name.sub(/^get_/, '')
#       send(:alias, rubified_method_name.to_sym, method_name.to_sym)
#     end
#   end
# 
#   def inspect
#     @instance.inspect
#   end
#   
#   def method_missing(method_name, *args, &block)
#     get_method_name = "get_" + method_name.to_s
#     if @instance.respond_to?(get_method_name)
#       @instance.send(get_method_name, *args, &block)
#     else
#       super
#     end
#   end
# end
# default_opts = {:hostname => "http://localhost:4502/crx/server", :username => "admin", :password => "admin"}
# username, password = ARGV[1].split(":") unless ARGV[1].nil?
# opts = default_opts.merge({:hostname => ARGV.first, :username => username, :password => password})
# jcr = JCR.new(:hostname => opts[:hostname], :username => opts[:username], :password => opts[:password])
jcr = JCR.new(:hostname => "http://localhost:4502/crx/server", :username => "admin", :password => "admin")
puts "logged in as " + jcr.username + " in " + jcr.repository_name
Ripl.start :binding => binding
# comments_node = jcr.session.get_node("/content/usergenerated/content/sfu/")

jcr.session.logout
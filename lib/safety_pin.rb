raise "Platform is #{RUBY_PLATFORM}, must be java. Please run using JRuby: http://jruby.org/" unless RUBY_PLATFORM == "java"

require 'java'
Dir.glob("#{File.dirname(__FILE__)}/**/*.jar").each {|jar| require jar }

require_relative 'safety_pin/jcr'
require_relative 'safety_pin/node'
require_relative 'safety_pin/node_blueprint'
require_relative 'safety_pin/query'
require_relative 'safety_pin/query/where_condition'

module SafetyPin
end
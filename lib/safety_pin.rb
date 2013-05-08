$: << File.dirname(__FILE__)

raise "Platform is #{RUBY_PLATFORM}, must be java. Please run using JRuby: http://jruby.org/" unless RUBY_PLATFORM == "java"

require 'java'
Dir.glob("**/*.jar").each {|jar| require jar }
require 'safety_pin/jcr'
require 'safety_pin/node'
require 'safety_pin/node_blueprint'
require 'safety_pin/query'
require 'safety_pin/query/where_condition'

module SafetyPin
end
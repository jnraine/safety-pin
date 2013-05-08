$:<<File.dirname(__FILE__)
require 'lib/safety_pin'

include SafetyPin

puts "Connecting to #{ENV["HOST"]}"
JCR.login(hostname: ENV["HOST"], username: ENV["USERNAME"], password: ENV["PASSWORD"])
#!/usr/bin/env ruby
require 'pp'
require_relative '../environment.rb'

if ARGV[0] == '--truncate'
  puts "Truncating data"
  Agent.connection.execute("TRUNCATE TABLE works")
  Agent.connection.execute("TRUNCATE TABLE agent_works")
  Agent.connection.execute("UPDATE agents SET processed_works = NULL")
end

puts 'Starting to populate works'
Work.populate_works
puts 'Done populating works'
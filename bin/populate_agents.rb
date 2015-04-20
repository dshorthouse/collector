#!/usr/bin/env ruby
require 'pp'
require_relative '../environment.rb'

if ARGV[0] == '--truncate'
  puts "Truncating data"
  Occurrence.connection.execute("TRUNCATE TABLE agents")
  Occurrence.connection.execute("TRUNCATE TABLE occurrence_determiners")
  Occurrence.connection.execute("TRUNCATE TABLE occurrence_recorders")
end

puts 'Starting to populate agents'
Occurrence.populate_agents
puts 'Done populating agents'
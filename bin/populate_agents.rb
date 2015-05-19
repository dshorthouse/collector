#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

if ARGV[0] == '--truncate'
  puts "Truncating data"
  Occurrence.connection.execute("TRUNCATE TABLE agents")
  Occurrence.connection.execute("TRUNCATE TABLE occurrence_determiners")
  Occurrence.connection.execute("TRUNCATE TABLE occurrence_recorders")
  Occurrence.connection.execute("TRUNCATE TABLE descriptions")
  Occurrence.connection.execute("TRUNCATE TABLE agent_descriptions")
end

puts 'Starting to populate agents'
Occurrence.populate_agents
Description.populate_agents
graphs = Collector::Disambiguator.new
graphs.reconcile_agents
puts 'Done populating agents'
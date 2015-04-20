#!/usr/bin/env ruby
require 'pp'
require_relative '../environment.rb'

if ARGV[0] == '--flush'
  puts "Flushing data"
  Agent.connection.execute("UPDATE agents set orcid_matches = NULL and orcid_identifier = NULL")
end

puts 'Starting to populate ORCIDs'
Agent.populate_orcids
puts 'Done populating ORCIDs'
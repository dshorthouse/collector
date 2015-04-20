#!/usr/bin/env ruby
require 'pp'
require_relative '../environment.rb'

if ARGV[0] == '--truncate'
  puts "Truncating data"
  Occurrence.connection.execute("TRUNCATE TABLE taxa")
  Occurrence.connection.execute("TRUNCATE TABLE taxon_determiners")
end

puts 'Starting to populate taxa'
Occurrence.populate_taxa
puts 'Done populating taxa'
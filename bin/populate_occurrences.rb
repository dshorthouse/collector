#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

if ARGV[0] == '--truncate'
  puts "Truncating data"
  Occurrence.connection.execute("TRUNCATE TABLE occurrences")
end

puts 'Starting to populate occurrences'
Occurrence.populate_data ARGV[0]
puts 'Done populating occurrences'
#!/usr/bin/env ruby
require 'pp'
require_relative '../environment.rb'

if ARGV[0] == '--flush'
  puts "Flushing data"
  Work.connection.execute("UPDATE works SET citation = NULL, processed = NULL")
end

puts 'Starting to populate citations'
Work.populate_citations
puts 'Done populating citations'
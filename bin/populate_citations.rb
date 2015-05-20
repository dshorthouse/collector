#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

if ARGV[0] == '--reset'
  puts "Flushing data"
  Work.connection.execute("UPDATE works SET citation = NULL, processed = NULL")
end

puts 'Starting to populate citations'
Work.populate_citations
puts 'Done populating citations'
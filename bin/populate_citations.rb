#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: populate_citations.rb [options]"

  opts.on("-r", "--reset", "Reset data") do |a|
    options[:reset] = true
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options[:reset]
  puts "Resetting data"
  Work.connection.execute("UPDATE works SET citation = NULL, processed = NULL")
end

puts 'Starting to populate citations'
Work.populate_citations
puts 'Done populating citations'
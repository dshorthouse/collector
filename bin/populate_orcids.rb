#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: populate_orcids.rb [options]"

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
  Agent.connection.execute("UPDATE agents set processed_orcid = NULL and orcid = NULL")
end

puts 'Starting to populate ORCIDs'
Agent.populate_orcids
puts 'Done populating ORCIDs'
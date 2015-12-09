#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: populate_datasets.rb [options]"

  opts.on("-t", "--truncate", "Truncate data") do |a|
    options[:truncate] = true
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options[:truncate]
  puts "Truncating data"
  Dataset.connection.execute("TRUNCATE TABLE datasets")
  Dataset.connection.execute("TRUNCATE TABLE agent_datasets")
  Dataset.connection.execute("UPDATE agents SET processed_datasets = NULL")
end

puts 'Starting to populate datasets'
Dataset.populate_datasets
puts 'Done populating datasets'
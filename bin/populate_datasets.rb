#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

if ARGV[0] == '--truncate'
  puts "Truncating data"
  Dataset.connection.execute("TRUNCATE TABLE datasets")
  Dataset.connection.execute("TRUNCATE TABLE agent_datasets")
  Dataset.connection.execute("UPDATE agents SET processed_datasets = NULL")
end

puts 'Starting to populate datasets'
Dataset.populate_datasets
puts 'Done populating datasets'
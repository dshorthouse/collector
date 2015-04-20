#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

if ARGV[0] == '--flush'
  puts "Flushing the #{Collector::Config.elastic_index} index"
  index = Collector::ElasticIndexer.new
  index.delete
  puts "Flushed"
end

if ARGV[0] == '--rebuild-all'
  index = Collector::ElasticIndexer.new
  index.delete
  index.create
  puts "Populating taxa..."
  index.import_taxa
  puts "Populating agents..."
  index.import_agents
  puts "Populating occurrence..."
  index.import_occurrences
  puts "Refreshing the index..."
  index.refresh
  puts "Finished indexing #{Collector::Config.elastic_index}"
end

if ARGV[0] == '--rebuild-agents'
  index = Collector::ElasticIndexer.new
  puts "Populating agents..."
  index.delete_agents
  index.import_agents
  puts "Refreshing the index..."
  index.refresh
  puts "Finished indexing #{Collector::Config.elastic_index} agents"
end

if ARGV[0] == '--rebuild-occurrences'
  index = Collector::ElasticIndexer.new
  puts "Populating occurrences..."
  index.delete_occurrences
  index.import_occurrences
  puts "Refreshing the index..."
  index.refresh
  puts "Finished indexing #{Collector::Config.elastic_index} occurrences"
end

if ARGV[0] == '--rebuild-taxa'
  index = Collector::ElasticIndexer.new
  puts "Populating taxa..."
  index.delete_taxa
  index.import_taxa
  puts "Refreshing the index..."
  index.refresh
  puts "Finished indexing #{Collector::Config.elastic_index} taxa"
end
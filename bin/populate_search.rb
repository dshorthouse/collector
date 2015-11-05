#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

ARGV << '-h' if ARGV.empty?

options = {}
options[:type] = "d3"

OptionParser.new do |opts|
  opts.banner = "Usage:populate_search.rb [options]"

  opts.on("-f", "--flush", "Flush the index") do |f|
    options[:flush] = true
  end

  opts.on("-e", "--rebuild-all", "Rebuild the entire index") do |a|
    options[:rebuild_all] = true
  end

  opts.on("-i", "--rebuild-agents", "Rebuild the agent index") do |a|
    options[:rebuild_agents] = true
  end

  opts.on("-o", "--rebuild-occurrences", "Rebuild the occurrences index") do |a|
    options[:rebuild_occurrences] = true
  end

  opts.on("-t", "--rebuild-taxa", "Rebuild the taxa index") do |a|
    options[:rebuild_taxa] = true
  end

  opts.on("-r", "--refresh", "Refresh the index") do |a|
    options[:refresh] = true
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!

index = Collector::ElasticIndexer.new

if options[:flush]
  puts "Flushing the #{settings.elastic_index} index"
  index.delete
  puts "Flushed"
end

if options[:refresh]
  puts "Refreshing the index..."
  index.refresh
  puts "Finished refreshing the index."
end

if options[:rebuild_all]
  puts "Flushing the index..."
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
  puts "Finished indexing #{settings.elastic_index}"
elsif options[:rebuild_agents]
  puts "Populating agents..."
  index.delete_agents
  index.import_agents
  puts "Refreshing the index..."
  index.refresh
  puts "Finished indexing #{settings.elastic_index} agents"
elsif options [:rebuild_occurrences]
  puts "Populating occurrences..."
  index.delete_occurrences
  index.import_occurrences
  puts "Refreshing the index..."
  index.refresh
  puts "Finished indexing #{settings.elastic_index} occurrences"
elsif options[:rebuild_taxa]
  puts "Populating taxa..."
  index.delete_taxa
  index.import_taxa
  puts "Refreshing the index..."
  index.refresh
  puts "Finished indexing #{settings.elastic_index} taxa"
end
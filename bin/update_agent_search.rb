#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

if !ARGV[0]
  puts "Agent id is required"
  exit 1
end

index = Collector::ElasticIndexer.new
puts "Updaing agent..."
index.update_agent ARGV[0]
puts "Finished updaing agent."
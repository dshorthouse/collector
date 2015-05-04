#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

if !ARGV[0] || !ARGV[1]
  puts "Agent id and orcid are required"
  exit 1
end

index = Collector::ElasticIndexer.new
puts "Updating agent..."
#format: id, orcid
index.update_agent(ARGV[0], ARGV[1])
puts "Finished updaing agent."
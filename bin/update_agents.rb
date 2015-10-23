#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

ARGV << '-h' if ARGV.empty?

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: update_agents.rb [options]"

  opts.on("--agent [JSON]", String, "Update single agent search with a JSON string of options") do |h|
    options[:all_agents] = false
    options[:agent_attributes] = JSON.parse(h)
  end

  opts.on("-a", "--all-agents", "Update all agents search with new data") do |a|
    options[:all_agents] = true
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options[:all_agents]
  Agent.where("id = canonical_id").find_each do |a|
    puts a.id
    index = Collector::ElasticIndexer.new
    index.update_agent(a)
  end
  puts "Done"
else
  attributes = options[:agent_attributes]
  a = Agent.find(attributes["id"])
  puts "Updating %{given} %{family} ..." % { given: a.given, family: a.family}
  a.update_attributes(attributes)
  puts "Refreshing ORCID data..."
  a.refresh_orcid_data
  Work.populate_citations
  puts "Refreshing the search index..."
  index = Collector::ElasticIndexer.new
  index.update_agent(a)
  puts "Done"
end


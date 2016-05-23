#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'
require 'progressbar'

ARGV << '-h' if ARGV.empty?

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: update_agents.rb [options]"

  opts.on("--agent [JSON]", String, "Update single agent search with a JSON string of options, '{\"id\": 1, \"orcid:\" \"000-000-000-000\"}'") do |h|
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

index = Collector::ElasticIndexer.new

if options[:all_agents]
  Parallel.map(Agent.where("id = canonical_id").find_each, progress: "Agents") do |a|
    index.update_agent(a)
  end
else
  attributes = options[:agent_attributes]
  a = Agent.find(attributes["id"])
  puts "Updating %{name} ..." % { name: a.fullname }
  a.update_attributes(attributes)
  a.refresh_orcid_data
  Work.populate_citations
  index.update_agent(a)
end


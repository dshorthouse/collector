#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

ARGV << '-h' if ARGV.empty?

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage:agent_waypoint.rb [options]"

  opts.on("-e", "--all-agents", "Generate graph files for all agents") do |a|
    options[:all_agents] = true
  end

  opts.on("-a", "--agent-id N", Integer, "Generate graph file for single agent") do |a|
    options[:agent_id] = a
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!

if options[:all_agents]
  puts 'Creating agent waypoint graphs for errors'
  agents = Agent.where("id = canonical_id")
  pbar = ProgressBar.new("Agents", agents.count)
  count = 0
  agents.find_each do |a|
    count += 1
    pbar.set(count)
    next if File.file?("public/images/graphs/waypoints/#{a.id}.dot")
    graph = Collector::AgentWaypoint.new(a.id)
    graph.build
  end
  pbar.finish
elsif options[:agent_id]
  graph = Collector::AgentWaypoint.new(a.id)
  graph.build
end
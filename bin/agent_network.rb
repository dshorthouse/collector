#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

ARGV << '-h' if ARGV.empty?

options = {}
options[:type] = "d3"
options[:depth] = 1

OptionParser.new do |opts|
  opts.banner = "Usage:agent_network.rb [options]"

  opts.on("-e", "--all-agents", "Generate graph files for all agents") do |a|
    options[:all_agents] = true
  end

  opts.on("-a", "--agent-id N", Integer, "Generate graph file for single agent") do |a|
    options[:agent_id] = a
  end

  opts.on("-n", "--whole-network", "Generate graph file for entire social network") do |a|
    options[:social_network] = true
  end

  opts.on("-k", "--kingdom [KINGDOM]", "Generate graph file for Kingdoms") do |k|
    options[:kingdom] = k
  end

  opts.on("-p", "--phylum [PHYLUM]", "Generate graph file for Phyla") do |p|
    options[:phylum] = p
  end

  opts.on("-t", "--type [TYPE]", "Type of output, options are dot or d3") do |t|
    if ['dot', 'd3'].include? t
      options[:type] = t
    end
  end

  opts.on("-d", "--depth N", Integer, "The depth of the agent network") do |d|
    options[:depth] = d
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!

if options[:social_network]
  puts 'Starting to create graph for whole network as ' + options[:type]
  graph = Collector::SocialNetwork.new
  graph.build
  puts 'Done creating whole network'
elsif options[:kingdom]
  puts 'Starting to create graph for Kingdoms as ' + options[:type]
  graph = Collector::KingdomNetwork.new(options[:kingdom])
  graph.build(options[:type])
  puts 'Done creating Kingdom networks'
elsif options[:phylum]
  puts 'Starting to create graph for Phyla as ' + options[:type]
  graph = Collector::PhylumNetwork.new(options[:phylum])
  graph.build(options[:type])
  puts 'Done creating Phylum networks'
elsif options[:all_agents]
  puts 'Starting to create all agent network graphs as ' + options[:type]
  Agent.where("id = canonical_id").find_each do |agent|
    graph = Collector::AgentNetwork.new(agent.id, options[:depth])
    graph.build(options[:type])
  end
  puts 'Done creating agent network graphs'
elsif options[:agent_id]
  puts 'Creating agent network graph as ' + options[:type]
  graph = Collector::AgentNetwork.new(options[:agent_id], options[:depth])
  graph.build(options[:type])
  puts 'Done creating agent network graph'
end
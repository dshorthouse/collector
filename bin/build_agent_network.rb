#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

ARGV << '-h' if ARGV.empty?

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: build_agent_network.rb [options]"

  opts.on("-r", "--reset", "Reset") do |a|
    options[:reset] = true
  end

  opts.on("--agent [ID]", Integer, "Build and save network for select agent") do |id|
    options[:agent_id] = id
  end

  opts.on("-a", "--all", "Build and save network for all agents") do
    options[:all_agents] = true
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!


if options[:reset]
  Agent.connection.execute("UPDATE agents set network_cache = NULL")
end

if options[:agent_id]
  agent = Agent.find(options[:agent_id])
  puts "Building network for #{agent.fullname}"
  agent.network_cache = agent.network(use_cache: false).to_json
  agent.save
end

if options[:all_agents]
  agents = Agent.where("id = canonical_id")
  pbar = ProgressBar.create(title: "Networks", total: agents.count, autofinish: false, format: '%t %b>> %i| %e')
  agents.find_each do |agent|
    pbar.increment
    next if agent.network_cache
    agent.network_cache = agent.network(use_cache: false).to_json
    agent.save
  end
  pbar.finish
end

puts 'Done building network'
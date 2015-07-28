#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

if !ARGV[0]
  puts "Command line switch --all or an integer for an agent id is required"
  exit
end

if ARGV[0] == '--all'
  puts 'Starting to create all agent network graphs'
  Agent.where("id = canonical_id").find_each do |agent|
    graph = Collector::AgentNetwork.new(agent.id)
    graph.build
  end
  puts 'Done creating agent network graphs'
end

puts 'Creating agent network graph'
graph = Collector::AgentNetwork.new(ARGV[0].to_i)
graph.build
puts 'Done creating agent network graph'
#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

puts 'Starting to create agent network graph'
Agent.where("id = canonical_id").find_each do |agent|
  graph = Collector::AgentNetwork.new(agent.id)
  graph.build
end
puts 'Done creating agent network graph'
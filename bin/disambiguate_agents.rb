#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

puts 'Starting to disambiguate agents'
graphs = Collector::AgentDisambiguator.new

if ARGV[0] == '--reset'
  graphs.reset
end

graphs.disambiguate
puts 'Starting to reassign data'
graphs.reassign_data
puts 'Done reconciling agents'
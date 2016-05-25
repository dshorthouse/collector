#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'benchmark'

iterations = 10

agent = Agent.find(4191)

Benchmark.bm do |bm|

  bm.report("network") do
    iterations.times do
      agent.network
    end
  end
end
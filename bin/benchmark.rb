#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'benchmark'

iterations = 1_000

utility = Collector::AgentUtility
name = "A.A. Beetle"
name_string = "A.A. Beetle and D.E. Beetle & Alva Hansen"
parsed = Namae.parse("Smith, Jack")

Benchmark.bm do |bm|
  bm.report("Namae1") do
    iterations.times do
      Namae.parse name
    end
  end

  bm.report("Parse1") do
    iterations.times do
      utility.parse name
    end
  end

  bm.report("Parse2") do
    iterations.times do
      utility.parse name_string
    end
  end

  bm.report("Clean") do
    iterations.times do
      utility.clean parsed[0]
    end
  end
end
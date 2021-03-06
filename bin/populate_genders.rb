#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: populate_genders.rb [options]"

  opts.on("-r", "--reset", "Resetting data") do |a|
    options[:truncate] = true
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options[:reset]
  Agent.connection.execute("UPDATE agents SET gender = NULL")
end

Agent.populate_genders
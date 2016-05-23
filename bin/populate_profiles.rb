#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: populate_profiles.rb [options]"

  opts.on("-t", "--truncate", "Truncate data") do |a|
    options[:truncate] = true
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options[:truncate]
  Agent.connection.execute("TRUNCATE TABLE works")
  Agent.connection.execute("TRUNCATE TABLE agent_works")
  Agent.connection.execute("UPDATE agents SET email = NULL, position = NULL, affiliation = NULL, processed_profile = NULL")
end

Agent.populate_profiles
#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

if ARGV[0] == '--reset'
  puts "Flushing data"
  Agent.connection.execute("UPDATE agents SET gender = NULL")
end

puts 'Starting to populate genders'
Agent.populate_genders
puts 'Done populating genders'
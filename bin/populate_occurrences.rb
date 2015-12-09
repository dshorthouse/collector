#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

ARGV << '-h' if ARGV.empty?

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: populate_occurrences.rb [options]"

  opts.on("--file [FILE]", "Full path to txt file") do |f|
    options[:file] = f
  end

  opts.on("-t", "--truncate", "Truncate data") do |a|
    options[:truncate] = true
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options[:truncate]
  puts "Truncating data"
  Occurrence.connection.execute("TRUNCATE TABLE occurrences")
end

if options[:file]
  puts 'Starting to populate occurrences'
  Occurrence.populate_data options[:file]
  puts 'Done populating occurrences'
end
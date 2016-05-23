#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: populate_barcodes.rb [options]"

  opts.on("-t", "--truncate", "Truncate data") do |a|
    options[:truncate] = true
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options[:truncate]
  Barcode.connection.execute("TRUNCATE TABLE barcodes")
  Barcode.connection.execute("TRUNCATE TABLE agent_barcodes")
  Barcode.connection.execute("UPDATE agents SET processed_barcodes = NULL")
end

Barcode.populate_barcodes
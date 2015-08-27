#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

if ARGV[0] == '--truncate'
  puts "Truncating data"
  Barcode.connection.execute("TRUNCATE TABLE barcodes")
  Barcode.connection.execute("TRUNCATE TABLE agent_barcodes")
  Barcode.connection.execute("UPDATE agents SET processed_barcodes = NULL")
end

puts 'Starting to populate barcodes'
Barcode.populate_barcodes
puts 'Done populating barcodes'
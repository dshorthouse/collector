#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

ARGV << '-h' if ARGV.empty?

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage:import_csv.rb [options]"

  opts.on("-f", "--file [file]", String, "File path to csv file") do |file|
    options[:file] = file
  end

  opts.on("-d", "--directory [directory]", String, "Directory containing 1+ csv file(s)") do |directory|
    options[:directory] = directory
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!

def import_file(file_path)
  attributes = Occurrence.attribute_names
  attributes.shift

  file = File.new(file_path)
  pbar = ProgressBar.create(title: "CSV", total: file.readlines.size, autofinish: false, format: '%t %b>> %i| %e')

  batch,batch_size = [], 5_000 
  CSV.foreach(file_path, options = { headers: true, return_headers: false, col_sep: "\t", quote_char: "\x00"}) do |row|
    pbar.increment
    batch << Occurrence.new(row.to_h.slice(*attributes))
    if batch.size >= batch_size
      Occurrence.import batch, validate: false
      batch = []
    end
  end
  Occurrence.import batch
  pbar.finish
end

if options[:file]
  csv_file = options[:file]
  raise "File not found" unless File.exists?(csv_file)
  import_file(csv_file)
end

if options[:directory]
  directory = options[:directory]
  raise "Directory not foud" unless File.directory?(directory)
  accepted_formats = [".csv"]
  files = Dir.entries(directory).select {|f| accepted_formats.include?(File.extname(f))}
  files.each do |file|
    import_file(File.join(directory, file))
  end
end
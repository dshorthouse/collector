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
  file = File.new(file_path)
  pbar = ProgressBar.create(title: "CSV", total: file.readlines.size, autofinish: false, format: '%t %b>> %i| %e')

  attributes = Occurrence.attribute_names
  attributes_hash = Hash[attributes.map(&:downcase).map.with_index.to_a]

  quote_chars = %w(" | ~ ^ & *)
  
  begin
    CSV.foreach(file_path, options = { headers: true, return_headers: false, col_sep: "\t", quote_char: quote_chars.shift}) do |row|
      pbar.increment
      new_record = {}
      row.each do |key,value|
        new_record[attributes[attributes_hash[key.downcase]].to_sym] = value if attributes_hash[key.downcase]
      end
      Occurrence.create(new_record)
    end
  rescue CSV::MalformedCSVError
    quote_chars.empty? ? raise : retry
  end

  pbar.finish
end

if options[:file]
  dwc_file = options[:file]
  raise "File not found" unless File.exists?(dwc_file)
  import_file(dwc_file)
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
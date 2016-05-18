#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

ARGV << '-h' if ARGV.empty?

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage:import_dwc.rb [options]"

  opts.on("-f", "--file [file]", String, "File path to dwc archive file") do |file|
    options[:file] = file
  end

  opts.on("-d", "--directory [directory]", String, "Directory containing 1+ dwc archive file(s)") do |directory|
    options[:directory] = directory
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!

def import_file(dwc_file)
  dwc = DarwinCore.new(dwc_file)
  file = File.new(dwc.core.file_path)
  title = dwc.metadata.data[:eml][:dataset][:title] rescue "Import"
  pbar = ProgressBar.create(title: title, total: file.readlines.size, autofinish: false, format: '%t %b>> %i| %e')
  fields = dwc.core.data[:field].map{|f| { index: f[:attributes][:index], field: f[:attributes][:term].split("/")[-1].to_sym }}

  dwc.core.read do |data, errors|
    data.each do |record|
      pbar.increment
      new_record = {}
      record.each_with_index do |value, index|
        field = fields.select{|f| f[:index] == index}[0][:field] rescue :nil
        new_record[field] = value
      end
      occurrence = Occurrence.new
      occurrence.attributes = new_record.reject{|k,v| !occurrence.attributes.keys.member?(k.to_s) }
      occurrence.save
    end
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
  accepted_formats = [".zip", ".gzip"]
  files = Dir.entries(directory).select {|f| accepted_formats.include?(File.extname(f))}
  files.each do |file|
    import_file(File.join(directory, file))
  end
end
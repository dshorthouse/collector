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

  opts.on("-d", "--directory [directory]", String, "Directory containing 1+ DwC archive file(s)") do |directory|
    options[:directory] = directory
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!

def import_file(dwc_file, progress = true)
  begin
    dwc = DarwinCore.new(dwc_file)
    title = dwc.metadata.data[:eml][:dataset][:title] rescue "DwC"
    fields = {}
    dwc.core.data[:field].each{|f| fields[f[:attributes][:index].to_s] = f[:attributes][:term].split("/")[-1].to_sym}
    file = File.new(dwc.core.file_path)
    pbar = ProgressBar.create(title: title, total: file.readlines.size, autofinish: false, format: '%t %b>> %i| %e') if progress

    attributes = Occurrence.attribute_names
    dwc.core.read(500) do |data, errors|
      Occurrence.transaction do
        data.each do |record|
          pbar.increment if progress
          new_record = {}
          record.each_with_index do |value, index|
            field = fields[index.to_s]
            new_record[field] = value if attributes.member?(field.to_s)
          end
          Occurrence.create(new_record)
        end
      end
    end
    pbar.finish if progress
  rescue Exception => e
    puts "#{dwc_file} failed"
  end
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
  Parallel.map(files.in_groups_of(5, false), progress: "Bulk") do |batch|
    batch.each do |file|
      import_file(File.join(directory, file), false)
    end
  end
end
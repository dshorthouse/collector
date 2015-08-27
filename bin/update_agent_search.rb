#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

Agent.where("id = canonical_id").find_each do |a|
  client = Elasticsearch::Client.new
  doc = {
    doc: {
      id: a.id,
      barcodes: a.barcodes.pluck(:processid,:bin_uri).uniq.map{ |b| { processid: b[0], bin_uri: b[1] } }
    }
  }
  client.update index: Sinatra::Application.settings.elastic_index, type: 'agent', id: a.id, body: doc
  puts a.id
end
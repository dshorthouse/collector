#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'
require 'optparse'

ARGV << '-h' if ARGV.empty?

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: update_agents.rb [options]"

  opts.on("--agent [JSON]", String, "Update single agent search with a JSON string of options, '{\"id\": 1, \"orcid:\" \"000-000-000-000\"}'") do |h|
    options[:agent_attributes] = JSON.parse(h)
  end

  opts.on("-a", "--all", "Update all agents") do |a|
    options[:all] = true
  end

  opts.on("-d", "--delete [id]", Integer, "Delete agent [id] from index") do |id|
    options[:delete] = id
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

index = Collector::ElasticIndexer.new

if options[:delete]
  agent = Agent.find(options[:delete])
  agent.destroy
  index.delete_agent(agent)
end

if options[:agent_attributes]
  attributes = options[:agent_attributes]
  a = Agent.find(attributes["id"])
  puts "Updating %{name} ..." % { name: a.fullname }
  a.update_attributes(attributes)
  a.refresh_orcid_data
  Work.populate_citations
  index.update_agent(a)
  a.recordings_with.each do |colleague|
    index.update_agent(colleague)
  end
end

if options[:all]
  models = [
    "AgentBarcode",
    "AgentDataset",
    "AgentDescription",
    "AgentWork",
    "OccurrenceDeterminer",
    "OccurrenceRecorder",
    "TaxonDeterminer"
  ]
  canonical_agent_ids = []
  colleagues = Set.new

  reconciled_agents = Agent.where("id != canonical_id")
  pbar = ProgressBar.create(title: "UpdateAgents", total: reconciled_agents.count, autofinish: false, format: '%t %b>> %i| %e')
  reconciled_agents.find_each do |agent|
    pbar.increment
    canonical_agent_ids << agent.canonical_id
    models.each do |model|
      model.constantize.where(agent_id: agent.id).update_all(agent_id: agent.canonical_id)
    end
    index.delete_agent(agent)
  end
  pbar.finish

  pbar = ProgressBar.create(title: "GetColleagues", total: canonical_agent_ids.uniq.size, autofinish: false, format: '%t %b>> %i| %e')
  canonical_agent_ids.uniq.each do |canonical_id|
    pbar.increment
    colleagues.merge(Agent.find(canonical_id).recordings_with)
  end
  pbar.finish

  Parallel.map(colleagues.to_a.in_groups_of(10, false), progress: "UpdateColleagues") do |batch|
    batch.each do |colleague|
      index.update_agent(colleague)
    end
  end
end



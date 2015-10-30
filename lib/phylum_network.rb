# encoding: utf-8
require 'byebug'
require 'rgl/adjacency'
require 'rgl/connected_components'
require 'rgl/dot'

module Collector
  class PhylumNetwork

    def initialize(phylum)
      @graph = WeightedGraph.new
      phyla = ['Arthropoda']
      if phyla.include? phylum
        @phylum = phylum
      end
    end

    def build(type = "dot")
      Agent.joins("INNER JOIN occurrence_recorders ocr ON agents.id = ocr.agent_id INNER JOIN taxon_occurrences tao ON ocr.occurrence_id = tao.occurrence_id INNER JOIN taxa t ON t.id = tao.taxon_id")
           .distinct
           .where('t.phylum = ?', @phylum)
           .where('agents.id = agents.canonical_id')
           .where('agents.given != ""')
           .find_in_batches(batch_size: 10) do |batch|
        batch.each do |agent|
          vertex = [agent.given, agent.family].join(" ")
          options = {}
          options["id"] = agent.id
          options["gender"] = agent.gender if !agent.gender.nil?
          agent.recordings_with.each do |r|
            agent2 = Agent.find(r[:id])
            if agent2.given.length > 0 && agent2.recordings.map{|t| t["phylum"]}.uniq.include?(@phylum)
              add_edge(agent, agent2)
            end
          end
          @graph.add_vertex_attributes(vertex, options)
          puts "Added #{agent.id}, #{agent.given} #{agent.family}"
        end
      end

      if type == "dot"
        write_dot_file
      else
        write_d3_file
      end
      puts "Created graph"
    end

    def add_edge(agent1, agent2)
      vertex1 = [agent1.given, agent1.family].join(" ")
      vertex2 = [agent2.given, agent2.family].join(" ")
      common = agent1.recordings.pluck(:id) & agent2.recordings.pluck(:id)
      @graph.add_edge(vertex1, vertex2, common.size) if common.size > 1
    end

    def write_dot_file
      @graph.write_to_dot_file("public/images/graphs/phylum/#{@phylum}")
    end

    def write_d3_file
      @graph.write_to_d3_file("public/images/graphs/phylum/#{@phylum}")
    end

  end
end
# encoding: utf-8
require 'byebug'
require 'rgl/adjacency'
require 'rgl/connected_components'
require 'rgl/dot'

module Collector
  class WholeNetwork

    def initialize
      @graph = WeightedGraph.new
    end

    def build(type = "dot")
      Agent.where('id = canonical_id').find_in_batches(batch_size: 10) do |batch|
        batch.each do |agent|
          vertex = [agent.given, agent.family].join(" ")
          options = {}
          options["id"] = agent.id
          options["gender"] = agent.gender if !agent.gender.nil?
          agent.recordings_with.each do |r|
            add_edge(agent, Agent.find(r[:id]))
          end
          @graph.add_vertex_attributes(vertex, options)
        end
        puts "Batch completed"
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
      @graph.write_to_dot_file("public/images/graphs/graph")
    end

    def write_d3_file
      @graph.write_to_d3_file("public/images/graphs/graph")
    end

  end
end
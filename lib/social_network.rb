# encoding: utf-8
require 'byebug'
require 'rgl/adjacency'
require 'rgl/connected_components'
require 'rgl/dot'

module Collector
  class SocialNetwork

    def initialize
      @graph = {
        nodes: Set.new,
        edges: Set.new
      }
    end

    def build
      Agent.where('id = canonical_id').find_in_batches(batch_size: 10) do |batch|
        batch.each do |agent|
          agent.recordings_with.each do |r|
            add_elements(agent, Agent.find(r[:id]))
          end
        end
      end

      write_to_d3_file
      puts "Created graph"
    end

    def add_elements(agent1, agent2)
      common = agent1.recordings.pluck(:id) & agent2.recordings.pluck(:id)
      if common.size > 0
        @graph[:nodes].merge([ { id: agent1.id, label: agent1.fullname }, { id: agent2.id, label: agent2.fullname } ])
        edge = [agent1.id, agent2.id].sort
        @graph[:edges].add({ from: edge[0], to: edge[1] })
      end
    end

    def write_to_d3_file
      src = "public/images/graphs/socialgraph.json"
      File.open(src, 'w') do |f|
        f << @graph.to_json
      end
      src
    end

  end
end
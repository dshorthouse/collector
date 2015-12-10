# encoding: utf-8
require 'byebug'
require 'rgl/adjacency'
require 'rgl/connected_components'
require 'rgl/dot'

module Collector
  class AgentNetwork

    def initialize(id)
      @graph = WeightedGraph.new
      @agent = Agent.find(id)
      @agents = []
    end

    def build(type = "dot")
      if @agent.id != @agent.canonical_id
        @agent = Agent.find(@agent.canonical_id)
      end
      collect_agents(@agent)
      add_edges
      add_attributes
      if @graph.size > 2
        if type == "dot"
          write_dot_file
        else
          write_d3_file
        end
        puts "Graph for #{[@agent.id, @agent.fullname].join(' ')}"
      end
    end

    def collect_agents(agent)
      @agents << agent
      agent.recordings_with.each do |a|
        @agents << Agent.find(a[:id])
      end
    end

    def add_edges
      @agents.combination(2).each do |pair|
        add_edge(pair.first, pair.second)
      end
    end

    def add_attributes
      @agents.each do |a|
        options = {}
        vertex = [a.given, a.family].join(" ")
        if @graph.has_vertex?(vertex)
          options["id"] = a.id
          if !a.gender.nil?
            options["gender"] = a.gender
          end
          @graph.add_vertex_attributes(vertex, options)
        end
      end
    end

    def add_edge(agent1, agent2)
      vertex1 = [agent1.given, agent1.family].join(" ")
      vertex2 = [agent2.given, agent2.family].join(" ")
      common = agent1.recordings.pluck(:id) & agent2.recordings.pluck(:id)
      @graph.add_edge(vertex1, vertex2, common.size) if common.size > 1
    end

    def write_dot_file
      @graph.write_to_dot_file("public/images/graphs/agents/#{@agent.id}")
    end

    def write_d3_file
      @graph.write_to_d3_file("public/images/graphs/agents/#{@agent.id}")
    end

  end
end
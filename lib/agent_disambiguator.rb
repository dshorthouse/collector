# encoding: utf-8
require 'byebug'
require 'rgl/adjacency'
require 'rgl/connected_components'
require 'rgl/dot'

module Collector
  class AgentDisambiguator

    def initialize
      @graph = {}
      @family = nil
    end

    def reset
      Agent.connection.execute("UPDATE agents set canonical_id = id")
    end

    def disambiguate
      duplicates = Agent.where('family not like "%.%"').group(:family).count.map{ |k,v| k if v > 1 }.compact
      duplicates.each do |d|
        @graph = WeightedGraph.new
        @family = d
        agents = []
        Agent.where(family: d).find_each do |a|
           if !a.given.empty?
            agents << {
              id: a.id, 
              given: a.given,
              collected_with: a.recordings_with.map{ |k| k[:family] },
              determined_families: a.determined_families
            }
          end
        end
        add_edges(agents)
        deduce_canonicals
        @graph.write_to_graphic_file('png', 'graphs/' + @family) if @graph.length > 2
      end
    end

    def add_edges(agents)
      agents.combination(2).each do |pair|
        similarity = name_similarity(pair.first, pair.second)
        vertex1 = { id: pair.first[:id], given: pair.first[:given] }
        vertex2 = { id: pair.second[:id], given: pair.second[:given] }
        @graph.add_edge(vertex1, vertex2, similarity)
        @graph.remove_edge(vertex1, vertex2) if similarity <= 0.5
      end
    end

    def deduce_canonicals
      #remove isolates
      @graph.isolates.each do |i|
        @graph.remove_vertex i
      end
      @graph.each_connected_component do |component|
        fully_connected = fully_connected_subgraph?(component)
        update_vertices(component) if fully_connected
        if component.length == 3 && !fully_connected
          unacceptable_edge_weight = component.combination(2).to_a.any? { |p| (@graph.weight(p.first, p.second).nil? ? 0.8 : @graph.weight(p.first, p.second)) < 0.8 }
          update_vertices(component) unless unacceptable_edge_weight
        end
        if component.length > 3
          #create cliques, set canonical_id
          #could use @graph.cycles here somehow and incorporate their weights
          #could try removing all vertices with 4+ edges then running through deduce_canonicals again
        end
      end
    end

    def fully_connected_subgraph?(vertices)
      @graph.edges.length == vertices.combination.length
    end

    def update_vertices(vertices)
      sorted_vertices = vertices.sort_by { |g| g[:given].length }
      ids = sorted_vertices.map {|v| v[:id] }
      agents = Agent.where(id: ids)
      agents.update_all(canonical_id: sorted_vertices[sorted_vertices.length-1][:id])
      puts sorted_vertices.map {|v| v[:given] }.join(" | ") + " => " + [sorted_vertices[sorted_vertices.length-1][:given],@family].join(" ")
      sorted_vertices.each do |v|
        @graph.remove_vertex v
      end
    end

    def name_similarity(agent1, agent2)
      given1 = agent1[:given]
      given2 = agent2[:given]
      given1_arr = given1.split(" ")
      given2_arr = given2.split(" ")
      initials1 = given1.gsub(/([[:upper:]])[[:lower:]]+/, '\1.').gsub(/\s+/, '')
      initials2 = given2.gsub(/([[:upper:]])[[:lower:]]+/, '\1.').gsub(/\s+/, '')
      initials1_arr = initials1.split(".")
      initials2_arr = initials2.split(".")
      shared_friends = agent1[:collected_with] & agent2[:collected_with]
      shared_friends_boost = (shared_friends.size > 0) ? 0.1 : 0
      shared_ids = agent1[:determined_families] & agent2[:determined_families]
      shared_ids_boost = (shared_ids.size > 0) ? 0.05 : 0

      #Exact match - not going to happen with these data
      if given1 == given2
        return 1
      end

      #Given names totally different strings eg Timothy & Thomas
      #TODO: incorporate nicknames here
      if !given1.empty? &&
         !given2.empty? &&
         !given1_arr[0].include?(".") &&
         !given2_arr[0].include?(".") &&
          given1_arr[0] != given2_arr[0]
        return 0
      end

      #Unabbreviated given names, one has middle initial (eg Timothy A. and Timothy)
      if (given1.include?(" ") || given2.include?(" ")) &&
         (initials1_arr.size == 1 || initials2_arr.size == 1) &&
         given1_arr[0] == given2_arr[0]
        return 0.90
      end

      #Both given names are composites
      if initials1_arr.size > 1 && initials2_arr.size > 1
        #Second initial does not match (eg. T.A. and T.R.)
        if initials1_arr[0] == initials2_arr[0] &&
            initials1_arr[1] != initials2_arr[1]
          return 0
        end
        #All initials match (eg. Timothy A. and T.A.)
        if initials1 == initials2
          return (0.80 + shared_friends_boost + shared_ids_boost).round(2)
        end
        #First and second initials match
        if initials1_arr[0] == initials2_arr[0] && initials1_arr[1] == initials2_arr[1]
          return (0.70 + shared_friends_boost + shared_ids_boost).round(2)
        end
      end

      #First initial in common (eg. Timothy and T.)
      if initials1_arr[0] == initials2_arr[0]
        return (0.50 + shared_friends_boost + shared_ids_boost).round(2)
      end

      #One of pair empty but there are shared friends
      if (given1.empty? || given2.empty?) && shared_friends.size > 0
        return 0.4
      end

      #One of pair empty but there are shared ids
      if (given1.empty? || given2.empty?) && shared_ids.size > 0
        return 0.2
      end

      return 0
    end

  end
end
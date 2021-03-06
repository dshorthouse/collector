# encoding: utf-8
require 'rgl/adjacency'
require 'rgl/connected_components'
require 'rgl/dot'

module Collector
  class AgentDisambiguator

    attr_accessor :write_graphics
    attr_accessor :cutoff_weight

    def initialize
      @graph = {}
      @cutoff_weight = 0.8
    end

    def reset
      Agent.connection.execute("UPDATE agents SET canonical_id = id")
    end

    def disambiguate
      duplicates = Agent.where("family NOT LIKE '%.%'")
                        .group(:family).count
                        .map{ |k,v| k if v > 1 }.compact
      Parallel.map(duplicates.in_groups_of(100), progress: "Disambiguations") do |batch|
        batch.each do |d|
          @graph = WeightedGraph.new
          agents = []

          Agent.where(family: d).find_each do |a|
             if !a.given.empty?
              agents << {
                id: a.id, 
                given: a.given,
                collected_with: a.recordings_with.map(&:family).uniq,
                determined_families: a.determined_families,
                recordings_year_range: a.recordings_year_range
              }
            end
          end
          add_edges(agents)
          write_graphic_file(d, 'raw') if @write_graphics
          prune_graph
          write_graphic_file(d, 'pruned') if @write_graphics
          combine_subgraphs
        end
      end
    end

    def add_edges(agents)
      agents.combination(2).each do |pair|
        similarity = name_similarity(pair.first, pair.second)
        vertex1 = { id: pair.first[:id], given: pair.first[:given] }
        vertex2 = { id: pair.second[:id], given: pair.second[:given] }
        @graph.add_edge(vertex1, vertex2, similarity) if similarity > 0
      end
    end

    def prune_graph
      edges = graph_edges(@graph.vertices)
      edges.each do |k,v|
        @graph.remove_edge(k[0],k[1]) if v < @cutoff_weight
      end
      remove_isolates
    end

    def write_graphic_file(family, type)
      if @graph.length > 1
        @graph.write_to_graphic_file('png', 'public/images/graphs/' + family.gsub(/[^0-9A-Za-z.\-]/, '_') + "_" + type)
      end
    end

    def graph_edges(vertices)
      edges = {}
      vertices.combination(2).each do |pair|
        if @graph.has_edge?(pair.first, pair.second)
          edges[[pair.first, pair.second]] = @graph.weight(pair.first, pair.second)
        end
      end
      edges
    end

    def combine_subgraphs
      @graph.each_connected_component do |vertices|
        sorted_vertices = vertices.sort_by { |g| g[:given].length }
        ids = sorted_vertices.map{|v| v[:id]}
        #TODO: make version with greatest number of objects the canonical version
        canonical = ids.pop
        Agent.where(id: ids).update_all(canonical_id: canonical)
      end
    end

    def remove_isolates
      @graph.isolates.each { |v| @graph.remove_vertex v }
    end

    def recordings_gap(agent1, agent2)
      agent1_range = agent1[:recordings_year_range]
      agent2_range = agent2[:recordings_year_range]
      diff1 = (agent1_range.max - agent2_range.min).abs rescue nil
      diff2 = (agent2_range.max - agent1_range.min).abs rescue nil
      [diff1, diff2].min
    end

    # TODO: not flexible enough to accommodate more nuances in score
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
      shared_friends_boost = (shared_friends.size > 0) ? 0.4 : 0
      shared_ids = agent1[:determined_families] & agent2[:determined_families]
      shared_ids_boost = (shared_ids.size > 0) ? 0.1 : 0
      recordings_gap = recordings_gap(agent1, agent2)

      #kick out pairs if difference in year ranges > 30
      if !recordings_gap.nil? && recordings_gap >= 30
        return 0
      end

      #Exact match - not going to happen with these data, but here anyway
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
        return adjust_score(0.90 + shared_friends_boost + shared_ids_boost)
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
          return adjust_score(0.80 + shared_friends_boost + shared_ids_boost)
        end
        #First and second initials match
        if initials1_arr[0] == initials2_arr[0] && initials1_arr[1] == initials2_arr[1]
          return adjust_score(0.70 + shared_friends_boost + shared_ids_boost)
        end
      end

      #First initial in common (eg. Timothy and T.)
      if initials1_arr[0] == initials2_arr[0]
        return adjust_score(0.50 + shared_friends_boost + shared_ids_boost)
      end

      #One of pair missing given name
      if (given1.empty? || given2.empty?)
        return adjust_score(0.40 + shared_friends_boost + shared_ids_boost)
      end

      return 0
    end

    def adjust_score(score)
      adjusted = (score > 1) ? 1 : score
      adjusted.round(2)
    end

    def reassign_data
      models = [
        "AgentBarcode",
        "AgentDataset",
        "AgentDescription",
        "AgentWork",
        "OccurrenceDeterminer",
        "OccurrenceRecorder",
        "TaxonDeterminer"
      ]
      agents = Agent.where("id != canonical_id")
      pbar = ProgressBar.create(title: "Reassign", total: agents.count, autofinish: false, format: '%t %b>> %i| %e')
      agents.find_each do |a|
        pbar.increment
        models.each do |model|
          model.constantize.where(agent_id: a.id).update_all(agent_id: a.canonical_id)
        end
      end
      pbar.finish
    end

    def erroneous_reassignment
      agents = Agent.where("id = canonical_id")
      pbar = ProgressBar.create(title: "Erroneous", total: agents.count, autofinish: false, format: '%t %b>> %i| %e')
      agents.find_each do |a|
        pbar.increment
        gap = a.recordings_year_range.max - a.recordings_year_range.min rescue 0
        if gap >= 50
          #Houston, we have a problem
        end
      end
      pbar.finish
    end

  end
end
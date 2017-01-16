# encoding: utf-8
require 'rgl/adjacency'
require 'rgl/connected_components'
require 'rgl/dot'
require 'fileutils'

module Collector
  class SocialNetwork < RGL::AdjacencyGraph

    def initialize
      super
      @agent_ids = Set.new
      @agents = []
      @attributes = {}
      @kingdoms = {}
    end

    def build
      collect_agent_ids
      collect_agent_data
      add_edges
      add_attributes
      remove_isolates
    end

    def collect_agent_ids
      occurrence_ids = OccurrenceRecorder.group("occurrence_id").having("count(*) > 4").pluck(:occurrence_id)
      pbar = ProgressBar.create(title: "CollectingAgents", total: occurrence_ids.count/50+1, autofinish: false, format: '%t %b>> %i| %e')
      occurrence_ids.in_groups_of(50, false) do |group|
        @agent_ids.merge(OccurrenceRecorder.where(occurrence_id: group).pluck(:agent_id).uniq)
        pbar.increment
      end
      pbar.finish
    end

    def collect_agent_data
      pbar = ProgressBar.create(title: "BuildingAgentData", total: @agent_ids.count/25+1, autofinish: false, format: '%t %b>> %i| %e')
      @agent_ids.to_a.in_groups_of(25, false) do |group|
        agents = Agent.find(group).map{|a| 
          { fullname: a.fullname, gender: a.gender, recordings: a.occurrence_recorders.pluck(:occurrence_id) } if !a.given.nil?
        }.compact
        @agents.push(*agents)
        pbar.increment
      end
      pbar.finish
    end

    def add_edge(u,v,w)
      super(u,v)
      @kingdoms[[u,v]] = w
    end

    def add_edges
      combinations = @agents.combination(2)
      pbar = ProgressBar.create(title: "AddingEdges", total: combinations.count, autofinish: false, format: '%t %b>> %i| %e')
      combinations.each do |pair|
        common = pair.first[:recordings] & pair.second[:recordings]
        shared_kingdom = TaxonOccurrence.find_by_occurrence_id(common.first).taxon.kingdom rescue nil
        self.add_edge(pair.first[:fullname], pair.second[:fullname], shared_kingdom) if common.size > 0
        pbar.increment
      end
      pbar.finish
    end

    def add_attributes
      pbar = ProgressBar.create(title: "AddingAttributes", total: @agents.count, autofinish: false, format: '%t %b>> %i| %e')
      @agents.each do |a|
        options = {}
        options[:style] = "filled"
        options[:fillcolor] = "white"
        if a[:gender] == "female"
          options[:fillcolor] = "lightpink"
        elsif a[:gender] == "male"
          options[:fillcolor] = "lightblue"
        end
        add_vertex_attributes(a[:fullname], options)
        pbar.increment
      end
      pbar.finish
    end

    # A set of all the unconnected vertices in the graph.
    def isolates
      edges.inject(Set.new(vertices)) { |iso, e| iso -= [e.source, e.target] }
    end

    def add_vertex_attributes(v, a)
      @attributes[v] = a
    end

    def vertex_attributes(v)
      @attributes[v] || {}
    end

    def kingdom(u,v)
      @kingdoms[[u,v]] || @kingdoms[[v,u]]
    end

    def remove_isolates
      isolates.each { |v| remove_vertex v }
    end

    def write_to_dot_file(file_name="graph")
      src = file_name + ".dot"

      File.open(src, 'w') do |f|
        f << self.to_dot_graph.to_s << "\n"
      end
      src
    end

    def write_to_graphic_file(fmt='png', file_name="graph")
      puts "Creating graphic..."
      src = write_to_dot_file(file_name)
      output = file_name + "." + fmt
      system("sfdp -Goutputorder=edgesfirst -Goverlap=prism -T#{fmt} #{src} > #{output}")
      output
    end


    def to_s
      # TODO Sort toplogically instead of by edge string.
      (edges.sort_by {|e| e.to_s} + 
       isolates.sort_by {|n| n.to_s}).map { |e| e.to_s }.join("\n")
    end

    def vertex_label(v)
      v.to_s
    end

    def vertex_id(v)
      v
    end

    def to_dot_graph(params = {})
      params[:name] ||= self.class.name.gsub(/:/, '_')
      fontsize       = params[:fontsize] ? params[:fontsize] : '8'
      graph          = RGL::DOT::Graph.new(params)
      edge_class     = RGL::DOT::Edge

      each_vertex do |v|
        options = {
          name: vertex_id(v),
          fontsize: fontsize,
          label: vertex_label(v)
        }
        options.merge! vertex_attributes(v)
        graph << RGL::DOT::Node.new(options.stringify_keys)
      end

      each_edge do |u, v|

        case kingdom(u,v)
        when "Animalia"
          color = "brown"
        when "Plantae"
          color = "green"
        when "Chromista"
          color = "blue"
        when "Fungi"
          color ="gold"
        when "Protozoa"
          color = "lightblue"
        else
          color = "black"
        end

        options = {
          from: vertex_id(u),
          to: vertex_id(v),
          fontsize: fontsize,
          color: color
        }
        graph << edge_class.new(options.stringify_keys)
      end

      graph
    end

  end
end
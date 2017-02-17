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
      @occurrences = {}
    end

    def build
      collect_agent_ids
      collect_agent_data
      add_edges
      add_attributes
      remove_isolates
    end

    def collect_agent_ids
      occurrence_ids = OccurrenceRecorder.group("occurrence_id").having("count(*) > 1").pluck(:occurrence_id)
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
      @occurrences[[u,v]] = w
    end

    def add_edges
      combinations = @agents.combination(2)
      pbar = ProgressBar.create(title: "AddingEdges", total: combinations.count, autofinish: false, format: '%t %b>> %i| %e')
      combinations.each do |pair|
        common = pair.first[:recordings] & pair.second[:recordings]
        self.add_edge(pair.first[:fullname], pair.second[:fullname], common) if common.size > 0
        pbar.increment
      end
      pbar.finish
    end

    def add_attributes
      pbar = ProgressBar.create(title: "AddingAttributes", total: @agents.count, autofinish: false, format: '%t %b>> %i| %e')
      @agents.each do |a|
        options = {}
        if edge_count(a[:fullname]) > 60
          options[:fontsize] = 16
        end
        if a[:gender] == "female"
          options[:fillcolor] = "#e55798"
        elsif a[:gender] == "male"
          options[:fillcolor] = "#3399ff"
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

    def edge_count(a)
      count = 0
      each_edge{|u,v| count += 1 if u == a || v == a}
      count
    end

    def occurrences(u,v)
      @occurrences[[u,v]] || @occurrences[[v,u]]
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
      graph          = RGL::DOT::Graph.new(params.stringify_keys)
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
        kingdom = Occurrence.find(occurrences(u,v).first).taxon.kingdom rescue nil
        weight = 1
        style = "filled"
        if occurrences(u,v).count.between?(2,50)
          style = "setlinewidth(2)"
          weight = 2
        elsif occurrences(u,v).count.between?(51,100)
          style = "setlinewidth(3)"
          weight = 3
        elsif occurrences(u,v).count > 100
          style = "setlinewidth(4)"
          weight = 4
        end

        case kingdom
        when "Animalia"
          color = "#f0f02e"
        when "Plantae"
          color = "#00ff04"
        when "Chromista"
          color = "#00f9ff"
        when "Fungi"
          color ="#fb7d00"
        when "Protozoa"
          color = "#00f9ff"
        when "Protista"
          color = "#00f9ff"
        else
          color = "#cccccc"
        end

        options = {
          from: vertex_id(u),
          to: vertex_id(v),
          color: color,
          style: style,
          weight: weight
        }
        graph << edge_class.new(options.stringify_keys)
      end

      graph
    end

  end
end
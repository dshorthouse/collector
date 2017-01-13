# encoding: utf-8
require 'rgl/adjacency'
require 'rgl/connected_components'
require 'rgl/dot'
require 'fileutils'

module Collector
  class SocialNetwork < RGL::AdjacencyGraph

    def initialize
      super
      @agents = []
      @attributes = {}
      @kingdom = {}
    end

    def add_edge(u, v, w)
      super(u,v)
      @kingdom[[u,v]] = w
    end

    def add_edges
      occurrence_ids = OccurrenceRecorder.group("occurrence_id").having("count(*) > 5").pluck(:occurrence_id)
      recorders = Occurrence.find(occurrence_ids).collect(&:recorders).flatten.uniq
      @agents = recorders.map{|a| 
        { fullname: a.fullname, gender: a.gender, recordings: a.occurrence_recorders.pluck(:occurrence_id) } if !a.given.nil? 
      }.compact
      @agents.combination(2).each do |pair|
        common = pair.first[:recordings] & pair.second[:recordings]
        kingdom = Occurrence.find(common.first).taxa.first.kingdom rescue nil
        self.add_edge(pair.first[:fullname], pair.second[:fullname], kingdom) if common.size > 0
      end
    end

    def add_attributes
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
      end
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

    def remove_isolates
      isolates.each { |v| remove_vertex v }
    end

    def write_to_dot_file(dotfile="graph")
      src = dotfile + ".dot"

      File.open(src, 'w') do |f|
        f << self.to_dot_graph.to_s << "\n"
      end
      src
    end

    def write_to_graphic_file(fmt='png', dotfile="graph")
      src = dotfile + ".dot"
      dot = dotfile + "." + fmt

      write_to_dot_file(dotfile)
      system("dot -T#{fmt} #{src} -o #{dot}")
      dot
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

    # Edge kingdom
    #
    # [_u_] source vertex
    # [_v_] target vertex
    def kingdom(u, v)
      @kingdom[[u,v]] || @kingdom[[v,u]]
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
        edge_color = "black"
        if kingdom(u,v) == "Animalia"
          edge_color = "maroon"
        elsif kingdom(u,v) == "Plantae"
          edge_color = "green"
        elsif kingdom(u,v) == "Fungi"
          edge_color = "orange"
        elsif kingdom(u,v) == "Protozoa"
          edge_color = "blue"
        elsif kingdom(u,v) == "Chromista"
          edge_color = "blue"
        end
        options = {
          from: vertex_id(u),
          to: vertex_id(v),
          fontsize: fontsize,
          color: edge_color
        }
        graph << edge_class.new(options.stringify_keys)
      end

      graph
    end

  end
end
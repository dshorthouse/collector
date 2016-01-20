# encoding: utf-8
require 'byebug'
require 'rgl/adjacency'
require 'rgl/connected_components'
require 'rgl/dot'

RGL::DOT::NODE_OPTS.push("coordinate")
RGL::DOT::NODE_OPTS.push("day")

class Numeric
  def to_rad
    self * Math::PI / 180
  end
end

module Collector
  class AgentWaypoint

    def initialize(id)
      @graph = WeightedDirectedGraph.new
      @agent = Agent.find(id)
    end

    def build
      if @agent.id != @agent.canonical_id
        @agent = Agent.find(@agent.canonical_id)
      end
      add_edges
      add_attributes
      if @graph.size > 2
        write_dot_file
      end
    end

    def add_edges
      @agent.recordings
            .reject{ |a| a.eventDate.empty? || a.coordinates.empty? }
            .sort{ |a,b| a.eventDate <=> b.eventDate }
            .each_cons(2) do |a|
              day1 = Collector::AgentUtility.valid_date(a[0].eventDate) rescue nil
              day2 = Collector::AgentUtility.valid_date(a[1].eventDate) rescue nil
              distance = haversine_distance(a[0].coordinates.reverse, a[1].coordinates.reverse)
              if !day1.nil? && !day2.nil? && (day2 - day1).to_i < 2 && distance > 600
                #@graph.add_edge(a[0].id, a[1].id, distance) #fishy edges here
              end
              @graph.add_edge(a[0].id, a[1].id, distance)
            end
    end

    def add_attributes
      first_date = Date.parse(Occurrence.find(@graph.vertices.first).eventDate)
      @graph.each_vertex do |v|
        o = Occurrence.find(v)
        options = {
          'coordinate' => o.coordinates.reverse.join(","),
          'day' => (Date.parse(o.eventDate) - first_date).to_i
        }
        @graph.add_vertex_attributes(v, options)
      end
    end

    def haversine_distance loc1, loc2
      lat1, lon1 = loc1
      lat2, lon2 = loc2
      dLat = (lat2-lat1).to_rad;
      dLon = (lon2-lon1).to_rad;
      a = Math.sin(dLat/2) * Math.sin(dLat/2) +
          Math.cos(lat1.to_rad) * Math.cos(lat2.to_rad) *
          Math.sin(dLon/2) * Math.sin(dLon/2);
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
      d = 6371 * c;
    end

    def write_dot_file
      @graph.write_to_dot_file("public/images/graphs/waypoints/#{@agent.id}")
    end

  end
end
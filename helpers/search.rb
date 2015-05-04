# encoding: utf-8

module Sinatra
  module Collector
    module Search

      def execute_search(type = 'taxon,agent')
        @results = []
        searched_term = params[:q]
        geo = params[:geo]
        return if !(searched_term.present? || geo.present?)

        page = (params[:page] || 1).to_i
        search_size = (params[:per] || 13).to_i

        center = params[:c] || "0,0"
        radius = (params[:r] || 0).to_s + "km"
        bounds = (params[:b] || "0,0,0,0").split(",").map(&:to_f) rescue [0,0,0,0]
        polygon = YAML::load(params[:p] || "[[0,0]]").map{ |n| n.reverse } rescue []

        body = { query: { match_all: {} } }
        fields = "id,family,given"
        sort = ""

        client = Elasticsearch::Client.new

        if searched_term.present?
          if searched_term.include?(":")
            components = searched_term.split(":",2)
            body = { query: { match: Hash[components[0], components[1]] } }
          elsif (type == 'taxon')
            body = { query: { match: { family: searched_term } }}
          elsif (type == 'occurrence')
            body = {
              query: {
                multi_match: {
                  query: searched_term,
                  type: 'best_fields',
                  fields: ["canonicalName", "epithet", "genus_abbrev"]
                }
              }
            }
          else
            parsed = Namae.parse searched_term
            name = ::Collector::Utility.clean_namae(parsed)
            family = !name.family.nil? ? name.family : ""
            given = !name.given.nil? ? name.given : ""

            body = {
              query: {
                bool: {
                  must: [
                    match: { family: family }
                  ],
                  should: [
                    match: { family: searched_term }
                  ],
                  should: [
                    match: { given: given }
                  ]
                }
              }
            }

          end
        end

        if geo.present?
          if !searched_term.present?
            sort = "family"
          end
          case geo
            when 'circle'
              body[:filter] = { geo_distance: { coordinates: center, distance: radius } }
            when 'rectangle'
              body[:filter] = { geo_bounding_box: { coordinates: { top_left: [bounds[1],bounds[2]], bottom_right: [bounds[3],bounds[0]] } } }
            when 'polygon'
              body[:filter] = { geo_polygon: { coordinates: { points: polygon } } }
          end
        end

        from = (page -1) * search_size

        response = client.search index: settings.elastic_index, type: type, fields: fields, from: from, size: search_size, sort: sort, body: body
        results = response["hits"].deep_symbolize_keys

        @results = WillPaginate::Collection.create(page, search_size, results[:total]) do |pager|
          pager.replace results[:hits]
        end
      end

      def agent_profile(id)
        @result = {}
        return if !id.present?

        client = Elasticsearch::Client.new
        body = { query: { match: { id: id } } }

        response = client.search index: settings.elastic_index, type: 'agent', body: body
        result = response["hits"].deep_symbolize_keys
        if result[:total] > 0
          @result = result[:hits][0][:_source]
        else
          halt(404)
        end
      end

      def taxon_profile(id)
        @result = {}
        return if !id.present?

        client = Elasticsearch::Client.new
        body = { query: { match: { id: id } } }

        response = client.search index: settings.elastic_index, type: 'taxon', body: body
        result = response["hits"].deep_symbolize_keys
        if result[:total] > 0
          @result = result[:hits][0][:_source]
        else
          halt(404)
        end
      end

      def agent_aggregation(id, precision = 3)
        @result = {}
        return if !id.present?

        if precision.nil? || precision < 1
          precision = 3
        elsif precision > 8
          precision = 8
        end

        client = Elasticsearch::Client.new

        body = {
          query: {
            multi_match: {
              query: id,
              fields: ["identifiedBy", "recordedBy"]
            }
          },
          aggregations: {
            determinations: {
              filter: { query: { match: { identifiedBy: id } } },
              aggregations: {
                histogram: {
                  date_histogram: {
                    field: "dateIdentified",
                    interval: "year",
                    format: "year",
                    min_doc_count: 0
                  }
                }
              }
            },
            recordings: {
              filter: { query: { match: { recordedBy: id } } },
              aggregations: {
                histogram: {
                  date_histogram: {
                    field: "eventDate",
                    interval: "year",
                    format: "year",
                    min_doc_count: 0
                  },
                  aggregations: {
                    geohash: {
                      geohash_grid: {
                        field: "coordinates",
                        precision: precision
                      }
                    }
                  }
                }
              }
            }
          }
        }

        response = client.search index: settings.elastic_index, type: "occurrence", search_type: "count", body: body
        @result = response.deep_symbolize_keys!
      end

      def format_agents
        @results.map{ |n| [n[:fields][:family][0].presence, n[:fields][:given][0].presence].compact.join(", ") }
      end

      def format_taxa
        @results.map{ |f| f[:fields][:family][0].presence }
      end

    end
  end
end
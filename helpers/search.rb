# encoding: utf-8

module Sinatra
  module Collector
    module Search

      def execute_search(type = 'taxon,agent')
        @results = []
        filters = []
        searched_term = params[:q]
        geo = params[:geo]
        taxon = params[:taxon]
        sort = params[:sort] ? ["collector_index:desc"] : []
        return if !(searched_term.present? || geo.present? || taxon.present?)

        page = (params[:page] || 1).to_i
        search_size = (params[:per] || 13).to_i

        center = params[:c] || "0,0"
        radius = (params[:r] || 0).to_s + "km"
        bounds = (params[:b] || "0,0,0,0").split(",").map(&:to_f) rescue [0,0,0,0]
        polygon = YAML::load(params[:p] || "[[0,0]]").map{ |n| n.reverse } rescue []

        body = { query: { match_all: {} } }
        fields = "id,family,personal.family,personal.given,orcid,collector_index"

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
            body = build_name_query(searched_term)
          end
        end

        if geo.present?
          if !searched_term.present?
            if type == "taxon"
              sort.push("family:asc")
            elsif type == "agent"
              sort.push("personal.family:asc")
            end
          end

          if type == "taxon"
            geo_circle = { geo_distance: { coordinates: center, distance: radius } }
            geo_bounding_box = { geo_bounding_box: { coordinates: { top_left: [bounds[1],bounds[2]], bottom_right: [bounds[3],bounds[0]] } } }
            geo_polygon = { geo_polygon: { taxon_coordinates: { points: polygon } } }
          elsif type == "agent"
            geo_circle = { geo_distance: { "recordings.coordinates" => center, distance: radius } }
            geo_bounding_box = { geo_bounding_box: { "recordings.coordinates" => { top_left: [bounds[1],bounds[2]], bottom_right: [bounds[3],bounds[0]] } } }
            geo_polygon = { geo_polygon: { "recordings.coordinates" => { points: polygon } } }
          end

          case geo
            when 'circle'
              filters << geo_circle
            when 'rectangle'
              filters << geo_bounding_box
            when 'polygon'
              filters << geo_polygon
          end
        end

        if taxon.present?
          if !searched_term.present?
            sort.push("family:asc")
          end
          filters << { term: { "determinations.families.family" => taxon } }
        end

        if filters.size > 0
          body[:filter] = { bool: { must: filters } }
        end

        from = (page -1) * search_size

        response = client.search index: settings.elastic_index, type: type, fields: fields, from: from, size: search_size, sort: sort, body: body
        results = response["hits"].deep_symbolize_keys

        @results = WillPaginate::Collection.create(page, search_size, results[:total]) do |pager|
          pager.replace results[:hits]
        end
      end

      def build_name_query(search)
        parsed = Namae.parse search
        name = ::Collector::AgentUtility.clean(parsed[0])
        family = !name[:family].nil? ? name[:family] : ""
        given = !name[:given].nil? ? name[:given] : ""
        {
          query: {
            bool: {
              must: [
                match: { "personal.family" => family }
              ],
              should: [
                match: { "personal.family" => search }
              ],
              should: [
                match: { "personal.given" => given }
              ]
            }
          }
        }
      end

      def agent_profile(search)
        @result = {}
        return if !search.present?

        client = Elasticsearch::Client.new

        if search.to_s == search.to_i.to_s
          body = { query: { match: { id: search.to_i } } }
        elsif /(\d{4})-(\d{4})-(\d{4})-(\d{3}[0-9X])/.match(search)
          body = { query: { match: { orcid: search } } }
        else
          body = build_name_query(CGI::unescape(search))
        end

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

        query = { match: { id: id.to_i } }
        if id.to_i == 0
          query = { match: { family: id } }
        end

        response = client.search index: settings.elastic_index, type: 'taxon', body: { query: query }
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
            bool: {
              should: [
                {
                  nested: {
                    path: "identifiedBy",
                    query: { match: { "identifiedBy.id" => id } }
                  }
                },
                {
                  nested: {
                    path: "recordedBy",
                    query: { match: { "recordedBy.id" => id } }
                  }
                }
              ]
            }
          },

          aggregations: {
            determinations: {
              filter: { query: { nested: { path: "identifiedBy", query: { match: { "identifiedBy.id" => id } } } } },
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
              filter: { query: { nested: { path: "recordedBy", query: { match: { "recordedBy.id" => id } } } } },
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
                        field: "occurrence_coordinates",
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

      def agent_roster
        @results = []
        client = Elasticsearch::Client.new

        body = {
          query: {
            match_all: {}
          },
          fields: ["id","personal.family","personal.given","orcid","collector_index"],
          sort: {
            collector_index: { order: "desc" }
          }
        }

        page = (params[:page] || 1).to_i
        search_size = (params[:per] || 50).to_i
        from = (page -1) * search_size

        response = client.search index: settings.elastic_index, type: 'agent', from: from, size: search_size, body: body
        results = response["hits"].deep_symbolize_keys

        @results = WillPaginate::Collection.create(page, search_size, results[:total]) do |pager|
          pager.replace results[:hits]
        end
      end

      def format_agents
        @results.map{ |n|
          orcid = n[:fields][:orcid][0].presence if n[:fields].has_key? :orcid
          { id: n[:fields][:id][0],
            name: [n[:fields][:"personal.family"][0].presence, n[:fields][:"personal.given"][0].presence].compact.join(", "),
            orcid: orcid,
            collector_index:  n[:fields][:collector_index][0]
          }
        }
      end

      def format_taxa
        @results.map{ |f| { id: f[:fields][:id][0], name: f[:fields][:family][0].presence } }
      end

    end
  end
end
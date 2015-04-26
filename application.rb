#!/usr/bin/env ruby
require 'sinatra'

class COLLECTOR < Sinatra::Base
  
  require File.join(File.dirname(__FILE__), 'environment')

  set :haml, :format => :html5
  set :public_folder, 'public'

  helpers WillPaginate::Sinatra::Helpers
  helpers Sinatra::ContentFor

  helpers do
    def paginate(collection)
        options = {
         inner_window: 3,
         outer_window: 3,
         previous_label: '&laquo;',
         next_label: '&raquo;'
        }
       will_paginate collection, options
    end

    def h(text)
      Rack::Utils.escape_html(text)
    end
  end

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
        name = Collector::Utility.clean_namae(parsed)
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

    response = client.search index: Collector::Config.elastic_index, type: type, fields: fields, from: from, size: search_size, sort: sort, body: body
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

    response = client.search index: Collector::Config.elastic_index, type: 'agent', body: body
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

    response = client.search index: Collector::Config.elastic_index, type: 'taxon', body: body
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

    response = client.search index: Collector::Config.elastic_index, type: "occurrence", search_type: "count", body: body
    @result = response.deep_symbolize_keys!
  end

  def format_agents
    @results.map{ |n| [n[:fields][:family][0].presence, n[:fields][:given][0].presence].compact.join(", ") }
  end

  def format_taxa
    @results.map{ |f| f[:fields][:family][0].presence }
  end

  get '/' do
    execute_search
    haml :home
  end

  get '/agent.json' do
    execute_search('agent')
    format_agents.to_json
  end

  get '/agent/:id' do
    agent_profile(params[:id].to_i)
    haml :agent
  end

  get '/agent/:id/activity.json' do
    agent_aggregation(params[:id].to_i, params[:zoom].to_i)
    @result.to_json
  end

  get '/taxon.json' do
    execute_search('taxon')
    format_taxa.to_json
  end

  get '/taxon/:id' do
    taxon_profile(params[:id].to_i)
    haml :taxon
  end

  get '/occurrence.json' do
    execute_search('occurrence')
    @results.to_json
  end

  get '/main.css' do
    content_type 'text/css', charset: 'utf-8'
    scss :main
  end

  not_found do
    status 404
    haml :oops
  end

  run! if app_file == $0

end
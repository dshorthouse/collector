# encoding: utf-8

module Sinatra
  module Collector
    module Routing
      module Main

        def self.registered(app)

          app.get '/' do
            if session[:omniauth]
              @orcid = session[:omniauth][:uid]
            end
            execute_search('agent')
            haml :home
          end

          app.get '/agent.json' do
            execute_search('agent')
            format_agents.to_json
          end

          app.get '/agent/:id.json' do
            agent_profile(params[:id])
            if @result[:id] != @result[:canonical_id]
              redirect to('/agent/' + @result[:canonical_id].to_s + '.json')
            end
            if !@result[:orcid].nil? && params[:id] != @result[:orcid]
              redirect to('/agent/' + @result[:orcid] + '.json' )
            end
            @result.to_json
          end

          app.get '/agent/:id' do
            agent_profile(params[:id])
            if @result[:id] != @result[:canonical_id]
              redirect to('/agent/' + @result[:canonical_id].to_s )
            end
            if !@result[:orcid].nil? && params[:id] != @result[:orcid]
              redirect to('/agent/' + @result[:orcid] )
            end
            haml :agent
          end

          app.get '/agent/:id/activity.json' do
            agent_aggregation(params[:id].to_i, params[:zoom].to_i)
            @result.to_json
          end

          app.get '/main.css' do
            content_type 'text/css', charset: 'utf-8'
            scss :main
          end

          app.get '/occurrence.json' do
            execute_search('occurrence')
            @results.to_json
          end

          app.get '/taxon.json' do
            execute_search('taxon')
            format_taxa.to_json
          end

          app.get '/taxon/:id.json' do
            taxon_profile(params[:id])
            @result.to_json
          end

          app.get '/taxon/:id' do
            taxon_profile(params[:id])
            haml :taxon
          end

          app.not_found do
            status 404
            haml :oops
          end

        end

      end
    end
  end
end
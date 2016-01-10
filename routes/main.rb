# encoding: utf-8

module Sinatra
  module Collector
    module Routing
      module Main

        def self.registered(app)

          app.before do
            set_session
          end

          app.get '/' do
            execute_search('agent')
            haml :home
          end

          app.get '/agent.json' do
            execute_search('agent')
            format_agents.to_json
          end

          app.get '/agent/:id.?:format?' do
            agent_profile(params[:id])
            extension = params[:format].nil? ? nil : "." + params[:format]

            if @result[:id] != @result[:canonical_id]
              redirect to("/agent/#{@result[:canonical_id]}#{extension}")
            end
            if !@result[:orcid].nil? && params[:id] != @result[:orcid]
              redirect to("/agent/#{@result[:orcid]}#{extension}")
            end

            if extension.nil?
              haml :agent
            elsif extension == ".json"
              @result["@context"] = "#{request.base_url}/contexts/collector.jsonld"
              @result.to_json
            end
          end

          app.put '/agent/:id' do
            protected!
            agent = Agent.find(params[:id])
            request.body.rewind
            request_payload = JSON.parse(request.body.read, :symbolize_names => true)
            agent.update(request_payload)
            agent.update_search(request_payload)
          end

          app.get '/agent/:id/activity.json' do
            agent_aggregation(params[:id].to_i, params[:zoom].to_i)
            @result.to_json
          end

          app.get '/contexts/collector.jsonld' do
            collector_context
            @context.to_json
          end

          app.get '/main.css' do
            content_type 'text/css', charset: 'utf-8'
            scss :main
          end

          app.get '/occurrence.json' do
            execute_search('occurrence')
            @results.to_json
          end

          app.get '/graph/:rank/:taxon' do
            ranks = ['kingdom', 'phylum', 'class', 'order', 'family']
            if ranks.include? params[:rank]
              @rank = params[:rank]
            end
            @taxon = params[:taxon]
            haml :graph
          end

          app.get '/socialgraph' do
            haml :socialgraph
          end

          app.get '/taxon.json' do
            execute_search('taxon')
            format_taxa.to_json
          end

          app.get '/taxon/:id.?:format?' do
            taxon_profile(params[:id])
            if params[:format].nil?
              set_session
              haml :taxon
            elsif params[:format] == "json"
              @result.to_json
            end
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
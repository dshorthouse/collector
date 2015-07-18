# encoding: utf-8

module Sinatra
  module Collector
    module Routing
      module Account

        def self.registered(app)
          app.get '/orcid_profile' do
            set_session
            get_orcid_profile(@orcid[:uid]).to_json
          end

          app.get '/logout' do
            session.clear
            redirect '/'
          end

          app.get '/auth/orcid/callback' do
            session_data = request.env['omniauth.auth']
            names = get_orcid_profile(session_data["uid"])[:"orcid-bio"][:"personal-details"]
            session_data[:name] = [names[:"given-names"][:value], names[:"family-name"][:value]].join(" ")
            session[:omniauth] = session_data
            redirect '/'
          end
        end
        
      end
    end
  end
end
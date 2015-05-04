# encoding: utf-8

module Sinatra
  module Collector
    module Routing
      module Account

        def self.registered(app)
          app.get '/orcid_profile' do
            client = OAuth2::Client.new app.settings.orcid_key, app.settings.orcid_secret, :site  => app.settings.orcid_site
            atoken = OAuth2::AccessToken.new client, session[:omniauth]['credentials']['token']
            response = atoken.get "/#{session[:omniauth]['uid']}/orcid-profile", :headers => {'Accept' => 'application/json'}
            response.body
          end

          app.get '/logout' do
            session.clear
            redirect '/'
          end

          app.get '/auth/orcid/callback' do
            session[:omniauth] = request.env['omniauth.auth']
            redirect '/'
          end
        end
        
      end
    end
  end
end
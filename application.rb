#!/usr/bin/env ruby
require './environment'

class COLLECTOR < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :haml, :format => :html5
  set :public_folder, 'public'

  register Sinatra::ConfigFile
  config_file File.join(root, 'config.yml')

  use Rack::Session::Cookie, :key => 'rack.session',
                             :path => '/',
                             :secret => settings.orcid_key

  use OmniAuth::Builder do
    provider :orcid, settings.orcid_key, settings.orcid_secret,
      :authorize_params => {
        :scope => '/authenticate'
      },
      :client_options => {
        :site => settings.orcid_site,
        :authorize_url => settings.orcid_authorize_url,
        :token_url => settings.orcid_token_url,
        :scope => '/authenticate'
      }
  end

  use Rack::GoogleAnalytics, :tracker => settings.google_analytics

  helpers WillPaginate::Sinatra::Helpers
  helpers Sinatra::ContentFor
  helpers Sinatra::Collector::Helpers
  helpers Sinatra::Collector::JsonLdContexts
  helpers Sinatra::Collector::Search

  register Sinatra::Collector::Routing::Main
  register Sinatra::Collector::Routing::Account
  register Sinatra::Collector::Model::Initialize

  run! if app_file == $0
end
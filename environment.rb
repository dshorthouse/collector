require 'bundler'
require 'ostruct'
require 'logger'
require 'mysql2'
require 'active_record'
require 'active_support/all'
require 'rest_client'
require 'json'
require 'sanitize'
require 'htmlentities'
require 'haml'
require 'sass'
require 'sinatra'
require 'sinatra/content_for'
require 'yaml'
require 'namae'
require 'elasticsearch'
require 'biodiversity'
require 'will_paginate'
require 'will_paginate/collection'
require 'will_paginate/view_helpers/sinatra'
require 'chronic'

module Collector
  
  def self.symbolize_keys(obj)
    if obj.class == Array
      obj.map {|o| Collector.symbolize_keys(o)}
    elsif obj.class == Hash
      obj.inject({}) {|res, data| res.merge(data[0].to_sym => Collector.symbolize_keys(data[1]))}
    else
      obj
    end
  end

  root_path = File.expand_path(File.dirname(__FILE__))
  CONF_DATA = Collector.symbolize_keys(YAML.load(open(File.join(root_path, 'config.yml')).read))
  conf = CONF_DATA
  environment = ENV['COLLECTOR_DEV'] || 'development'
  Config = OpenStruct.new(
                 root_path: root_path,
                 orcid_base_url: conf[:orcid_base_url],
                 orcid_client_id: conf[:orcid_client_id],
                 orcid_secret: conf[:orcid_secret],
                 environment: environment,
                 elastic_server: conf[:elastic_server],
                 elastic_index: conf[:elastic_index]
               )
  # load models
  ActiveSupport::Inflector.inflections do |inflect|
    inflect.irregular 'taxon', 'taxa'
  end
  db_settings = conf[Config.environment.to_sym]
  # ActiveRecord::Base.logger = Logger.new(STDOUT, :debug) if environment == 'test'
  ActiveRecord::Base.establish_connection(db_settings)
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib', 'collector'))
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'models'))
  Dir.glob(File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')) { |lib|   require File.basename(lib, '.*') }
  Dir.glob(File.join(File.dirname(__FILE__), 'models', '*.rb')) { |model| require File.basename(model, '.*') }
end


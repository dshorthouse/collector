# encoding: utf-8

module Sinatra
  module Collector
    module Model
      module Initialize

        def self.registered(app)
          ActiveRecord::Base.establish_connection(
            :adapter => app.settings.adapter,
            :database =>  app.settings.database,
            :host => app.settings.host,
            :username => app.settings.username,
            :password => app.settings.password
          )

          ActiveSupport::Inflector.inflections do |inflect|
            inflect.irregular 'taxon', 'taxa'
          end
        end

      end
    end
  end
end
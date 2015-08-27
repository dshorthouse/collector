# encoding: utf-8

module Sinatra
  module Collector
    module Helpers

      def set_session
        if session[:omniauth]
          @orcid = session[:omniauth]
        end
      end

      def get_orcid_profile(uid)
        response = RestClient::Request.execute(
          method: :get,
          url: Sinatra::Application.settings.orcid_api_url + uid + '/orcid-profile',
          headers: { accept: 'application/orcid+json' }
        )
        JSON.parse(response, :symbolize_names => true)[:"orcid-profile"]
      end

      def protected!
        return if authorized?
        halt 401, "Not authorized\n"
      end

      def authorized?
        defined? @orcid
      end

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

      def number_with_delimiter(number, default_options = {})
        options = {
          :delimiter => ','
        }.merge(default_options)
        number.to_s.reverse.gsub(/(\d{3}(?=(\d)))/, "\\1#{options[:delimiter]}").reverse
      end

    end
  end
end
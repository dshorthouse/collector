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

      def format_agent(n)
        orcid = n[:fields][:orcid][0].presence if n[:fields].has_key? :orcid
        { id: n[:fields][:id][0],
          name: [n[:fields][:"personal.family"][0].presence, n[:fields][:"personal.given"][0].presence].compact.join(", "),
          orcid: orcid,
          collector_index:  n[:fields][:collector_index][0]
        }
      end

      def cycle
        %w{even odd}[@_cycle = ((@_cycle || -1) + 1) % 2]
      end

    end
  end
end
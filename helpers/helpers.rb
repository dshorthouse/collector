# encoding: utf-8

module Sinatra
  module Collector
    module Helpers

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
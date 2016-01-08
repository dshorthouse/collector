# encoding: utf-8

module Sinatra
  module Collector
    module JsonLdContexts

      def collector_context
        @context = {
          "@context" => {
            "given" => "http://schema.org/givenName",
            "family" => "http://schema.org/familyName",
            "gender" => "http://schema.org/gender",
            "affiliation" => "http://schema.org/affiliation",
            "position" => "http://schema.org/jobTitle",
            "email" => "http://schema.org/email"
          }
        }
      end

    end
  end
end
# encoding: utf-8

module Sinatra
  module Collector
    module JsonLdContexts

      def collector_context
        @context = {
          "@context" => {
            "schema" => "http://schema.org/",
            "given" => "schema:givenName",
            "family" => "schema:familyName",
            "gender" => "schema:gender",
            "affiliation" => "schema:affiliation",
            "position" => "schema:jobTitle",
            "email" => "schema:email",
            "personal" => { 
              "@id" => "schema:Person",
              "@container" => "@set"
            },
            "recordings" => {
              "@id" => "_id",
              "container" => "@set",
              "with" => {
                "@id" => "schema:Person",
                "@container" => "@set"
              }
            }
          }
        }
      end

    end
  end
end
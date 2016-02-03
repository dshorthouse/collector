#encoding utf-8

module Collector
  module TaxonUtility

    PARSER = ScientificNameParser.new

    def self.canonical_species_name(s)
      species_name = nil
      parsed = PARSER.parse(s)
      if parsed[:scientificName][:parsed] && parsed[:scientificName][:details][0].has_key?(:species)
        species_name = parsed[:scientificName][:canonical]
      end
      species_name
    end

  end
end
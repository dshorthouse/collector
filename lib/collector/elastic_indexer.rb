module Collector
  class ElasticIndexer
    
    def initialize
      @client = Elasticsearch::Client.new
    end
    
    def delete
      if @client.indices.exists index: Collector::Config.elastic_index
        @client.indices.delete index: Collector::Config.elastic_index
      end
    end

    def delete_agents
      @client.delete_by_query index: Collector::Config.elastic_index, type: 'agent', q: '*'
    end

    def delete_occurrences
      @client.delete_by_query index: Collector::Config.elastic_index, type: 'occurrence', q: '*'
    end

    def delete_taxa
      @client.delete_by_query index: Collector::Config.elastic_index, type: 'taxon', q: '*'
    end

    def create
      config = {
        settings: {
          analysis: {
            tokenizer: {
              scientific_name_tokenizer: {
                type: "path_hierarchy",
                delimiter: " ",
                reverse: true
              }
            },
            filter: {
              autocomplete: {
                type: "edgeNGram",
                side: "front",
                min_gram: 1,
                max_gram: 50
              },
              genus_abbreviation: {
                type: "pattern_replace",
                pattern: "(^.)[^\\s]+",
                replacement: "$1."
              },
            },
            analyzer: {
              family_index: {
                type: "custom",
                tokenizer: "keyword",
                filter: ["lowercase", "asciifolding"]
              },
              family_search: {
                type: "custom",
                tokenizer: "keyword",
                filter: ["lowercase", "asciifolding"]
              },
              given_index: {
                type: "custom",
                tokenizer: "keyword",
                filter: ["lowercase", "asciifolding", :autocomplete]
              },
              given_search: {
                type: "custom",
                tokenizer: "keyword",
                filter: ["lowercase", "asciifolding", :autocomplete]
              },
              scientific_name_index: {
                type: "custom",
                tokenizer: "keyword",
                filter: ["lowercase", "asciifolding", :autocomplete]
              },
              scientific_name_search: {
                type: "custom",
                tokenizer: "keyword",
                filter: ["lowercase", "asciifolding"]
              },
              scientific_epithet_index: {
                type: "custom",
                tokenizer: :scientific_name_tokenizer,
                filter: ["lowercase", "asciifolding", :autocomplete]
              },
              scientific_genus_abbrev_index: {
                type: "custom",
                tokenizer: "keyword",
                filter: [:genus_abbreviation, "lowercase", "asciifolding", :autocomplete]
              }
            }
          }
        },
        mappings: {
          agent: {
            properties: {
              id: { type: 'integer', index: 'not_analyzed' },
              family: { type: 'string', search_analyzer: :family_search, index_analyzer: :family_index, omit_norms: true },
              given: { type: 'string', search_analyzer: :given_search, index_analyzer: :given_index, omit_norms: true },
              orcid: { type: 'string', index: 'not_analyzed' },
              email: { type: 'string', index: 'not_analyzed' },
              position: { type: 'string', index: 'not_analyzed' },
              affiliation: { type: 'string', index: 'not_analyzed' },
              coordinates: { type: 'geo_point', lat_lon: true, fielddata: { format: 'compressed', precision: "5km" }, index: 'not_analyzed' },
              determined_taxa: {
                properties: {
                  id: { type: 'integer', index: 'not_analyzed' },
                  family: {type: 'string', index: 'not_analyzed' },
                }
              },
              recordings_with: {
                type: 'nested',
                properties: {
                  id: { type: 'integer', index: 'not_analyzed' },
                  family: { type: 'string', index: 'not_analyzed' },
                  given: { type: 'string', index: 'not_analyzed' }
                }
              },
              works: {
                properties: {
                  doi: { type: 'string', index: 'not_analyzed' },
                  citation: { type: 'string', index: 'not_analyzed' }
                }
              }
            }
          },
          occurrence: {
            properties: {
              id: { type: 'integer', index: 'not_analyzed' },
              coordinates: { type: 'geo_point', lat_lon: true, fielddata: { format: 'compressed', precision: "100m" }, index: 'not_analyzed' },
              dateIdentified: { type: 'date', format: 'year' },
              identifiedBy: { type: 'integer', index: 'not_analyzed' },
              eventDate: { type: 'date', format: 'year' },
              recordedBy: { type: 'integer', index: 'not_analyzed' }
            }
          },
          taxon: {
            properties: {
              id: { type: 'integer', index: 'not_analyzed' },
              family: { type: 'string', search_analyzer: :scientific_name_search, index_analyzer: :scientific_name_index, omit_norms: true },
              identifiedBy: {
                type: 'nested',
                properties: {
                  id: {type: 'integer', index: 'not_analyzed' },
                  family: { type: 'string', index: 'not_analyzed' },
                  given: { type: 'string', index: 'not_analyzed' }
                }
              }
            }
          }
        }
      }
      @client.indices.create index: Collector::Config.elastic_index, body: config
    end

    def import_agents
      counter = 0
      Agent.find_in_batches(batch_size: 50) do |group|
        agents = []
        group.each do |a|
          agents << {
                      index: {
                        _id: a.id,
                        data: {
                          id: a.id,
                          family: a.family,
                          given: a.given,
                          orcid: a.orcid_identifier,
                          email: a.email,
                          position: a.position,
                          affiliation: a.affiliation,
                          coordinates: a.recordings_coordinates,
                          recordings_with: a.recordings_with,
                          determined_taxa: a.determined_taxa.uniq,
                          works: a.works.select("doi,citation")
                        }
                      }
                    }
        end
        @client.bulk index: Collector::Config.elastic_index, type: 'agent', body: agents
        counter += agents.size
        puts "Added #{counter} agents"
      end
    end

    def import_occurrences
      counter = 0
      parser = ScientificNameParser.new
      Occurrence.find_in_batches(batch_size: 1_000) do |group|
        occurrences = []
        group.each do |o|
          agents = o.agents
          occurrences << {
            index: {
              _id: o.id,
              data: {
                id: o.id,
                coordinates: o.coordinates,
                identifiedBy: agents[:determiners],
                dateIdentified: Collector::Utility.valid_year(o.dateIdentified),
                recordedBy: agents[:recorders],
                eventDate: Collector::Utility.valid_year(o.eventDate),
              }
            }
          }
        end
        @client.bulk index: Collector::Config.elastic_index, type: 'occurrence', body: occurrences
        counter += occurrences.size
        puts "Added #{counter} occurrences"
      end
    end

    def import_taxa
      counter = 0
      Taxon.find_in_batches(batch_size: 50) do |group|
        taxa = []
        group.each do |t|
          taxa << {
                    index: {
                      _id: t.id,
                      data: {
                        id: t.id,
                        family: t.family,
                        identifiedBy: t.determinations.select("agents.id,family,given").uniq
                      }
                    }
                  }
        end
        @client.bulk index: Collector::Config.elastic_index, type: 'taxon', body: taxa
        counter += taxa.size
        puts "Added #{counter} taxa"
      end
    end

    def update_agent(id)
      a = Agent.find(id)
      return if !a.present?

      body = {
                id: a.id,
                family: a.family,
                given: a.given,
                orcid: a.orcid_identifier,
                email: a.email,
                position: a.position,
                affiliation: a.affiliation,
                coordinates: a.recordings_coordinates,
                recordings_with: a.recordings_with,
                determined_taxa: a.determined_taxa.uniq,
                works: a.works.select("doi,citation")
              }

      @client.delete index: Collector::Config.elastic_index, type: 'agent', id: id rescue nil
      @client.create index: Collector::Config.elastic_index, type: 'agent', id: id, body: body
    end

    def refresh
      @client.indices.refresh index: Collector::Config.elastic_index
    end

  end
end
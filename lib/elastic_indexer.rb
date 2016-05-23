# encoding: utf-8

module Collector
  class ElasticIndexer

    def initialize
      @client = Elasticsearch::Client.new
      @settings = Sinatra::Application.settings
      @processes = 8
    end

    def delete
      if @client.indices.exists index: @settings.elastic_index
        @client.indices.delete index: @settings.elastic_index
      end
    end

    def delete_agents
      @client.delete_by_query index: @settings.elastic_index, type: 'agent', q: '*'
    end

    def delete_occurrences
      @client.delete_by_query index: @settings.elastic_index, type: 'occurrence', q: '*'
    end

    def delete_taxa
      @client.delete_by_query index: @settings.elastic_index, type: 'taxon', q: '*'
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
              canonical_id: { type: 'integer', index: 'not_analyzed' },
              orcid: { type: 'string', index: 'not_analyzed' },
              personal: {
                properties: {
                  family: { type: 'string', search_analyzer: :family_search, analyzer: :family_index, omit_norms: true },
                  given: { type: 'string', search_analyzer: :given_search, analyzer: :given_index, omit_norms: true },
                  gender: { type: 'string', index: 'not_analyzed' },
                  aka: {
                    type: 'nested',
                    properties: {
                      family: { type: 'string', index: 'not_analyzed' },
                      given: { type: 'string', index: 'not_analyzed' }
                    }
                  },
                  email: { type: 'string', index: 'not_analyzed' },
                  position: { type: 'string', index: 'not_analyzed' },
                  affiliation: { type: 'string', index: 'not_analyzed' }
                }
              },
              recordings: {
                properties: {
                  count: { type: 'integer', index: 'not_analyzed' },
                  with: {
                    type: 'nested',
                    properties: {
                      id: { type: 'integer', index: 'not_analyzed' },
                      family: { type: 'string', index: 'not_analyzed' },
                      given: { type: 'string', index: 'not_analyzed' }
                    }
                  },
                  coordinates: { type: 'geo_point', lat_lon: true, fielddata: { format: 'compressed', precision: "5km" }, index: 'not_analyzed' },
                  institutions: { type: 'string', index: 'not_analyzed' }
                }
              },
              determinations: {
                properties: {
                  count: { type: 'integer', index: 'not_analyzed' },
                  institutions: { type: 'string', index: 'not_analyzed' },
                  families: {
                    properties: {
                      id: { type: 'integer', index: 'not_analyzed' },
                      family: { type: 'string', index: 'not_analyzed' },
                      count: { type: 'integer', index: 'not_analyzed' }
                    }
                  }
                }
              },
              works: {
                properties: {
                  publications: {
                    properties: {
                      doi: { type: 'string', index: 'not_analyzed' },
                      citation: { type: 'string', index: 'not_analyzed' }
                    }
                  },
                  barcodes: {
                    properties: {
                      processid: { type: 'string', index: 'not_analyzed' },
                      bin_uri: { type: 'string', index: 'not_analyzed' }
                    }
                  },
                  named_species: {
                    properties: {
                      scientificName: { type: 'string', index: 'not_analyzed' },
                      year: { type: 'date', format: 'year' }
                    }
                  },
                  datasets: {
                    properties: {
                      doi: { type: 'string', index: 'not_analyzed' },
                      title: { type: 'string', index: 'not_analyzed' }
                    }
                  }
                }
              },
              network: {
                properties: {
                  nodes: {
                    properties: {
                      id: { type: 'integer', index: 'not_analyzed' },
                      label: { type: 'string', index: 'not_analyzed' },
                      gender: { type: 'string', index: 'not_analyzed' }
                    }
                  },
                  edges: {
                    properties: {
                      from: { type: 'integer', index: 'not_analyzed' },
                      to: { type: 'integer', index: 'not_analyzed' },
                      value: { type: 'integer', index: 'not_analyzed' },
                      title: { type: 'integer', index: 'not_analyzed' }
                    }
                  }
                }
              },
              collector_index: { type: 'integer' }
            }
          },
          occurrence: {
            properties: {
              id: { type: 'integer', index: 'not_analyzed' },
              occurrence_coordinates: { type: 'geo_point', lat_lon: true, fielddata: { format: 'compressed', precision: "100m" }, index: 'not_analyzed' },
              dateIdentified: { type: 'date', format: 'year' },
              identifiedBy: {
                type: 'nested',
                properties: {
                  id: { type: 'integer', index: 'not_analyzed' },
                  family: { type: 'string', index: 'not_analyzed' },
                  given: { type: 'string', index: 'not_analyzed' }
                }
              },
              eventDate: { type: 'date', format: 'year' },
              recordedBy: {
                type: 'nested',
                properties: {
                  id: { type: 'integer', index: 'not_analyzed' },
                  family: { type: 'string', index: 'not_analyzed' },
                  given: { type: 'string', index: 'not_analyzed' }
                }
              }
            }
          },
          taxon: {
            properties: {
              id: { type: 'integer', index: 'not_analyzed' },
              family: { type: 'string', search_analyzer: :scientific_name_search, analyzer: :scientific_name_index, omit_norms: true },
              common_name: { type: 'string', index: 'not_analyzed' },
              image_data: {
                properties: {
                  mediaURL: { type: 'string', index: 'not_analyzed' },
                  license: { type: 'string', index: 'not_analyzed' },
                  rightsHolder: { type: 'string', index: 'not_analyzed' },
                  source: { type: 'string', index: 'not_analyzed' }
                }
              },
              identifiedBy: {
                type: 'nested',
                properties: {
                  id: { type: 'integer', index: 'not_analyzed' },
                  family: { type: 'string', index: 'not_analyzed' },
                  given: { type: 'string', index: 'not_analyzed' },
                  count: { type: 'integer', index: 'not_analyzed' }
                }
              },
              taxon_coordinates: { type: 'geo_point', lat_lon: true, fielddata: { format: 'compressed', precision: "5km" }, index: 'not_analyzed' },
            }
          }
        }
      }
      @client.indices.create index: @settings.elastic_index, body: config
    end

    def import_agents
      Parallel.map(Agent.where("id = canonical_id").find_in_batches, progress: "Agents") do |batch|
        agents = []
        batch.each do |a|
            agents << {
              index: {
                _id: a.id,
                data: agent_document(a)
              }
            }
        end
        @client.bulk index: @settings.elastic_index, type: 'agent', refresh: false, body: agents
      end
    end

    def import_occurrences
      Parallel.map(Occurrence.find_in_batches, progress: "Occurrences") do |batch|
        occurrences = []
        batch.each do |o|
          date_identified = Collector::AgentUtility.valid_year(o.dateIdentified)
          event_date = Collector::AgentUtility.valid_year(o.eventDate)
          agents = o.agents
          occurrences << {
            index: {
              _id: o.id,
              data: {
                id: o.id,
                occurrence_coordinates: o.coordinates,
                identifiedBy: agents[:determiners],
                dateIdentified: !date_identified.nil? ? date_identified.to_s : nil,
                recordedBy: agents[:recorders],
                eventDate: !event_date.nil? ? event_date.to_s : nil
              }
            }
          }
        end
        @client.bulk index: @settings.elastic_index, type: 'occurrence', refresh: false, body: occurrences
      end
    end

    def import_taxa
      Parallel.map(Taxon.find_in_batches, progress: "Taxa") do |batch|
        taxa = []
        batch.each do |t|
          taxa << {
                  index: {
                    _id: t.id,
                    data: {
                      id: t.id,
                      family: t.family,
                      common_name: t.common,
                      image_data: t.image_data,
                      identifiedBy: t.determinations.pluck(:id, :given, :family).group_by{ |i| i }.map {|k, v| { id: k[0], given: k[1], family: k[2], count: v.count } },
                      taxon_coordinates: t.occurrence_coordinates
                    }
                  }
                }
        end
        @client.bulk index: @settings.elastic_index, type: 'taxon', refresh: false, body: taxa
      end
    end

    def update_agent(a)
      doc = { doc: agent_document(a) }

      @client.update index: @settings.elastic_index, type: 'agent', id: a.id, body: doc
    end

    def agent_document(a)
      network = a.network
      {
        id: a.id,
        canonical_id: a.canonical_id,
        orcid: a.orcid,
        personal: {
          family: a.family,
          given: a.given,
          gender: a.gender,
          aka: a.aka,
          email: a.email,
          position: a.position,
          affiliation: a.affiliation,
        },
        recordings: {
          count: a.occurrence_recorders.size,
          with: network[:nodes].reject{|h| h[:id] == a.id },
          institutions: a.recordings_institutions,
          coordinates: a.recordings_coordinates
        },
        determinations: {
          count: a.determinations.size,
          institutions: a.determinations_institutions,
          families: a.determined_families
        },
        works: {
          publications: a.works.select(:doi,:citation).uniq,
          barcodes: a.barcodes.select(:processid,:bin_uri).uniq,
          named_species: a.descriptions,
          datasets: a.datasets.select(:doi,:title).uniq
        },
        network: network,
        collector_index: a.collector_index
      }
    end

    def refresh
      @client.indices.refresh index: @settings.elastic_index
    end

  end
end
# encoding: utf-8

module Collector
  class ElasticIndexer

    def initialize
      @client = Elasticsearch::Client.new
      @settings = Sinatra::Application.settings
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
              family: { type: 'string', search_analyzer: :family_search, index_analyzer: :family_index, omit_norms: true },
              given: { type: 'string', search_analyzer: :given_search, index_analyzer: :given_index, omit_norms: true },
              gender: { type: 'string', index: 'not_analyzed' },
              aka: {
                type: 'nested',
                properties: {
                  family: { type: 'string', index: 'not_analyzed' },
                  given: { type: 'string', index: 'not_analyzed' }
                }
              },
              orcid: { type: 'string', index: 'not_analyzed' },
              email: { type: 'string', index: 'not_analyzed' },
              position: { type: 'string', index: 'not_analyzed' },
              affiliation: { type: 'string', index: 'not_analyzed' },
              coordinates: { type: 'geo_point', lat_lon: true, fielddata: { format: 'compressed', precision: "5km" }, index: 'not_analyzed' },
              determinations_count: { type: 'integer', index: 'not_analyzed' },
              determined_families: {
                properties: {
                  id: { type: 'integer', index: 'not_analyzed' },
                  family: { type: 'string', index: 'not_analyzed' },
                  count: { type: 'integer', index: 'not_analyzed' }
                }
              },
              recordings_count: { type: 'integer', index: 'not_analyzed' },
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
              },
              barcodes: {
                properties: {
                  processid: { type: 'string', index: 'not_analyzed' },
                  bin_uri: { type: 'string', index: 'not_analyzed' },
                  catalognum: { type: 'string', index: 'not_analyzed' }
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
              coordinates: { type: 'geo_point', lat_lon: true, fielddata: { format: 'compressed', precision: "5km" }, index: 'not_analyzed' },
            }
          }
        }
      }
      @client.indices.create index: @settings.elastic_index, body: config
    end

    def import_agents
      imports = Agent.where("id = canonical_id")
      pbar = ProgressBar.new("Agents", imports.count)
      counter = 0

      imports.find_in_batches(batch_size: 25) do |group|
        agents = []
        group.each do |a|
          agents << {
                      index: {
                        _id: a.id,
                        data: {
                          id: a.id,
                          canonical_id: a.canonical_id,
                          family: a.family,
                          given: a.given,
                          gender: a.gender,
                          aka: a.aka,
                          orcid: a.orcid_identifier,
                          email: a.email,
                          position: a.position,
                          affiliation: a.affiliation,
                          coordinates: a.recordings_coordinates,
                          recordings_count: a.recordings.size,
                          recordings_with: a.recordings_with,
                          determinations_count: a.determinations.size,
                          determined_families: a.determined_families,
                          works: a.works.pluck(:doi,:citation).uniq.map{ |c| { doi: c[0], citation: c[1] } },
                          barcodes: a.barcodes.pluck(:processid,:bin_uri).uniq.map{ |b| { processid: b[0], bin_uri: b[1] } },
                          named_species: a.descriptions,
                          datasets: a.datasets.pluck(:doi,:title).uniq.map{ |d| { doi: d[0], title: d[1] } }
                        }
                      }
                    }
        end
        @client.bulk index: @settings.elastic_index, type: 'agent', body: agents
        counter += agents.size
        pbar.set(counter)
      end

      pbar.finish
    end

    def import_occurrences
      pbar = ProgressBar.new("Occurrences", Occurrence.count)
      counter = 0
      parser = ScientificNameParser.new

      Occurrence.find_in_batches(batch_size: 1_000) do |group|
        occurrences = []
        group.each do |o|
          agents = o.agents
          date_identified = Collector::AgentUtility.valid_year(o.dateIdentified)
          event_date = Collector::AgentUtility.valid_year(o.eventDate)
          occurrences << {
            index: {
              _id: o.id,
              data: {
                id: o.id,
                coordinates: o.coordinates,
                identifiedBy: agents[:determiners],
                dateIdentified: !date_identified.nil? ? date_identified.to_s : nil,
                recordedBy: agents[:recorders],
                eventDate: !event_date.nil? ? event_date.to_s : nil
              }
            }
          }
        end
        @client.bulk index: @settings.elastic_index, type: 'occurrence', body: occurrences
        counter += occurrences.size
        pbar.set(counter)
      end

      pbar.finish
    end

    def import_taxa
      pbar = ProgressBar.new("Taxa", Occurrence.count)
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
                        common_name: t.common,
                        image_data: t.image_data,
                        identifiedBy: t.determinations.group_by{ |i| i }.map {|k, v| { id: k.id, given: k.given, family: k.family, count: v.count } },
                        coordinates: t.occurrence_coordinates
                      }
                    }
                  }
        end
        @client.bulk index: @settings.elastic_index, type: 'taxon', body: taxa
        counter += taxa.size
        pbar.set(counter)
      end

      pbar.finish
    end

    def update_agent(a)
      doc = {
        doc: {
          id: a.id,
          canonical_id: a.canonical_id,
          family: a.family,
          given: a.given,
          gender: a.gender,
          aka: a.aka,
          orcid: a.orcid_identifier,
          email: a.email,
          position: a.position,
          affiliation: a.affiliation,
          coordinates: a.recordings_coordinates,
          recordings_count: a.recordings.size,
          recordings_with: a.recordings_with,
          determinations_count: a.determinations.size,
          determined_families: a.determined_families,
          works: a.works.pluck(:doi,:citation).uniq.map{ |c| { doi: c[0], citation: c[1] } },
          barcodes: a.barcodes.pluck(:processid,:bin_uri).uniq.map{ |b| { processid: b[0], bin_uri: b[1] } },
          named_species: a.descriptions,
          datasets: a.datasets.pluck(:doi,:title).uniq.map{ |d| { doi: d[0], title: d[1] } }
        }
      }

      @client.update index: @settings.elastic_index, type: 'agent', id: a.id, body: doc
    end

    def refresh
      @client.indices.refresh index: @settings.elastic_index
    end

  end
end
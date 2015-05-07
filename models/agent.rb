class Agent < ActiveRecord::Base
  has_many :determinations, :through => :occurrence_determiners, :source => :occurrence
  has_many :occurrence_determiners

  has_many :recordings, :through => :occurrence_recorders, :source => :occurrence
  has_many :occurrence_recorders

  has_many :descriptions, :through => :agent_descriptions, :source => :description
  has_many :agent_descriptions

  has_many :determined_taxa, :through => :taxon_determiners, :source => :taxon
  has_many :taxon_determiners

  has_many :works, :through => :agent_works
  has_many :agent_works

  def self.populate_orcids
    search_orcid
  end

  def self.populate_profiles
    search_profile
  end

  def self.search_orcid
    Agent.where("orcid_matches IS NULL").find_each do |agent|
      agent.orcid_matches = 0
      if !agent.family.empty? && !agent.given.empty?
        max_year = [agent.determinations_year_range[1], agent.recordings_year_range[1]].compact.max
        if !max_year.nil? && max_year >= 1975
          search = 'family-name:' + URI::encode(agent.family) + '+AND+given-names:' + URI::encode(agent.given)
          response = RestClient::Request.execute(
            method: :get,
            url: Sinatra::Application.settings.orcid_base_url + 'search/orcid-bio?q=' + search,
            headers: { accept: 'application/orcid+json' }
          )
          parse_search_orcid_response(agent, response)
        end
      end
      agent.save!
    end
  end

  def self.parse_search_orcid_response(agent, response)
    hits = JSON.parse(response, :symbolize_names => true)[:"orcid-search-results"][:"orcid-search-result"] rescue []
    agent.orcid_matches = hits.length
    found = hits.length > 0 ? " ... found " + hits.length.to_s : ""
    agent.orcid_identifier = hits[0][:"orcid-profile"][:"orcid-identifier"][:path] if hits.length == 1
    puts "Searched orcid for " + agent.family + ", " + agent.given + found
  end

  def self.search_profile
    Agent.where("agents.orcid_matches = 1").find_each do |agent|
      next if agent.processed_profile
      response = RestClient::Request.execute(
        method: :get,
        url: Sinatra::Application.settings.orcid_base_url + agent.orcid_identifier + '/orcid-profile',
        headers: { accept: 'application/orcid+json' }
      )
      parse_profile_orcid_response(agent, response)
    end
  end

  def self.parse_profile_orcid_response(agent, response)

    doi_sub = %r{
      ^http\:\/\/dx\.doi\.org\/|
      ^(?i:doi\=?\:?\s+?)
    }x

    Agent.transaction do
      Agent.connection.execute("DELETE FROM agent_works WHERE agent_id = %s" % agent.id)

      profile = JSON.parse(response, :symbolize_names => true)[:"orcid-profile"]
      agent.email = profile[:"orcid-bio"][:"contact-details"][:email][0][:value] rescue nil
      agent.position = profile[:"orcid-activities"][:affiliations][:affiliation][0][:"role-title"] rescue nil
      agent.affiliation = profile[:"orcid-activities"][:affiliations][:affiliation][0][:organization][:name] rescue nil

      publications = profile[:"orcid-activities"][:"orcid-works"][:"orcid-work"] rescue []
      publications.each do |pub|
        identifiers = pub[:"work-external-identifiers"][:"work-external-identifier"] rescue []
        identifiers.each do |identifier|
            if identifier[:"work-external-identifier-type"] == "DOI"
              doi = identifier[:"work-external-identifier-id"][:value].gsub(doi_sub,'')
              work_id = Agent.connection.select_value("SELECT id FROM works WHERE doi = %s" % Work.connection.quote(doi))
              unless work_id
                work = Work.new
                work.doi = identifier[:"work-external-identifier-id"][:value].gsub(doi_sub,'')
                work.save!
                work_id = work.id
              end
              Agent.connection.execute("INSERT INTO agent_works (agent_id, work_id) VALUES (%s, %s)" % [agent.id, work_id])
              break
            end
        end
      end

      puts "Added profile for " + agent.id.to_s + ": " + agent.family + ", " + agent.given

      agent.processed_profile = true
      agent.save!
    end
  end

  def determinations_year_range
    years = determinations.pluck(:dateIdentified)
                          .map{ |d| Collector::Utility.valid_year(d) }
                          .compact
                          .minmax rescue [nil,nil]
    years[0] = years[1] if years[0].nil?
    years[1] = years[0] if years[1].nil?
    years
  end

  def recordings_year_range
    years = recordings.pluck(:eventDate)
                      .map{ |d| Collector::Utility.valid_year(d) }
                      .compact
                      .minmax rescue [nil,nil]
    years[0] = years[1] if years[0].nil?
    years[1] = years[0] if years[1].nil?
    years
  end

  def recordings_coordinates
    recordings.pluck(:decimalLongitude, :decimalLatitude)
              .compact.uniq
              .map{ |c| [c[0].to_f, c[1].to_f] }
  end

  def recordings_with
    occurrence_ids = occurrence_recorders.pluck(:occurrence_id)
    return [] if occurrence_ids.empty?
    OccurrenceRecorder.joins("JOIN agents ON occurrence_recorders.agent_id = agents.id")
                      .where(occurrence_id: occurrence_ids)
                      .where.not(agent_id: id)
                      .pluck(:agent_id, :given, :family)
                      .uniq
                      .map{ |a| { id: a[0], given: a[1], family: a[2] } }
                      .sort_by { |a| a[:family] }
  end

  def determined_species
    parser = ScientificNameParser.new
    determinations.pluck(:scientificName)
                  .compact.uniq.sort
                  .map{ |s| parser.parse(s)[:scientificName][:canonical] rescue s }
  end

  def determined_families
    determined_taxa.pluck(:id, :family).uniq.map{|f| { id: f[0], family: f[1] } }.sort_by { |a| a[:family] }
  end

  def refresh_orcid_data
    response = RestClient::Request.execute(
      method: :get,
      url: Sinatra::Application.settings.orcid_base_url + orcid_identifier + '/orcid-profile',
      headers: { accept: 'application/orcid+json' }
    )
    self.class.parse_profile_orcid_response(self, response)
  end

end
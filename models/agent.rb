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

  has_many :barcodes, :through => :agent_barcodes
  has_many :agent_barcodes

  has_many :aliases, class_name: "Agent", foreign_key: "canonical_id"
  belongs_to :canonical, class_name: "Agent"

  GENDER_HASH = {}

  def self.populate_orcids
    search_orcid
  end

  def self.populate_profiles
    search_profile
  end

  def self.populate_genders
    rebuild_gender_hash
    search_gender
  end

  def self.search_orcid
    Agent.where("id = canonical_id AND orcid_matches IS NULL").find_each do |agent|
      agent.orcid_matches = 0
      if !agent.family.empty? && !agent.given.empty?
        max_year = [agent.determinations_year_range[1], agent.recordings_year_range[1]].compact.max
        if !max_year.nil? && max_year >= 1975
          search = 'family-name:' + URI::encode(agent.family) + '+AND+given-names:' + URI::encode(agent.given)
          response = RestClient::Request.execute(
            method: :get,
            url: Sinatra::Application.settings.orcid_api_url + 'search/orcid-bio?q=' + search,
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
    Agent.where("orcid_matches = 1").find_each do |agent|
      next if agent.processed_profile
      response = RestClient::Request.execute(
        method: :get,
        url: Sinatra::Application.settings.orcid_api_url + agent.orcid_identifier + '/orcid-profile',
        headers: { accept: 'application/orcid+json' }
      )
      parse_profile_orcid_response(agent, response)
    end
  end

  def self.rebuild_gender_hash
    puts "Rebuilding list..."
    if Agent::GENDER_HASH.empty?
      Agent.where("gender IS NOT NULL").pluck(:given, :gender).uniq.each do |a|
        Agent::GENDER_HASH[a[0].split.first] = a[1]
      end
    end
    puts "List rebuilt."
  end

  # Using data from https://github.com/guydavis/babynamemap/blob/master/db.sql.gz
  def self.search_gender
    Agent.where("length(given) > 1 AND gender IS NULL").find_each do |a|
      first_name = a.given.split.first.strip
      next if first_name.include? "."
      gender = Agent::GENDER_HASH[first_name]
      unless gender
        searched = BabyName.where("name = %s" % BabyName.connection.quote(first_name))
                           .pluck(:gender, :rating_avg)
                           .map{ |n| { gender: n[0], rating: n[1].nil? ? 0 : n[1] } }
        if searched.size == 1
          gender = searched.first[:gender]
        elsif searched.size > 1
          gender = searched.sort_by{|k| k[:rating]}.reverse.first[:gender]
        else
          gender = "unknown"
        end
        Agent::GENDER_HASH[first_name] = gender
        puts first_name + " = " + gender
      end
      a.gender = gender
      a.save!
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
              work = Work.find_or_create_by(doi: doi)
              AgentWork.create(agent_id: agent.id, work_id: work.id)
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
                          .map{ |d| Collector::AgentUtility.valid_year(d) }
                          .compact
                          .minmax rescue [nil,nil]
    years[0] = years[1] if years[0].nil?
    years[1] = years[0] if years[1].nil?
    years
  end

  def recordings_year_range
    years = recordings.pluck(:eventDate)
                      .map{ |d| Collector::AgentUtility.valid_year(d) }
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
    determined_taxa.group_by{|i| i }.map {|k, v| { id: k.id, family: k.family, count: v.count } }.sort_by { |a| a[:family] }
  end

  def refresh_orcid_data
    return if !orcid_identifier.present?
    response = RestClient::Request.execute(
      method: :get,
      url: Sinatra::Application.settings.orcid_api_url + orcid_identifier + '/orcid-profile',
      headers: { accept: 'application/orcid+json' }
    )
    self.class.parse_profile_orcid_response(self, response)
  end

  def aka
    (Agent.where(canonical_id: id).where.not(id: id) | Agent.where(canonical_id: canonical_id).where.not(id: id)).map{|a| {family: a.family, given: a.given}}
  end

end
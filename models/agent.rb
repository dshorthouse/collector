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

  has_many :datasets, :through => :agent_datasets
  has_many :agent_datasets

  has_many :aliases, class_name: "Agent", foreign_key: "canonical_id"
  belongs_to :canonical, class_name: "Agent"

  GENDER_HASH = {}

  def self.populate_genders
    rebuild_gender_hash
    search_gender
  end

  def self.populate_orcids
    count = 0
    agents = Agent.where("id = canonical_id AND length(given) > 0 AND processed_orcid IS NULL")
    pbar = ProgressBar.new("ORCID", agents.count)

    agents.find_each do |agent|
      count += 1
      pbar.set(count)

      if !agent.family.empty? && !agent.given.empty?
        max_year = [agent.determinations_year_range.max, agent.recordings_year_range.max].compact.max
        given = URI::encode(agent.given.gsub(/\./, '. ').gsub(/&/,''))
        family = URI::encode(agent.family)
        if !max_year.nil? && max_year >= 1975
          search = 'given-names:' + given + '+AND+family-name:' + family + '+OR+other-names:' + given
          response = RestClient::Request.execute(
            method: :get,
            url: Sinatra::Application.settings.orcid_api_url + 'search/orcid-bio?q=' + search + '&rows=1',
            headers: { accept: 'application/orcid+json' }
          )
          parse_search_orcid_response(agent, response)
        end
      end

      agent.processed_orcid = true
      agent.save!
    end

    pbar.finish
  end

  def self.parse_search_orcid_response(agent, response)
    matches = {}
    results = JSON.parse(response, :symbolize_names => true)[:"orcid-search-results"][:"orcid-search-result"] rescue []
    results.each do |r|
      orcid_id = r[:"orcid-profile"][:"orcid-identifier"][:path] rescue nil
      orcid_given = r[:"orcid-profile"][:"orcid-bio"][:"personal-details"][:"given-names"][:value] rescue nil
      orcid_family = r[:"orcid-profile"][:"orcid-bio"][:"personal-details"][:"family-name"][:value] rescue nil
      orcid_credit = r[:"orcid-profile"][:"orcid-bio"][:"personal-details"][:"credit-name"][:value] rescue nil
      next if orcid_family != agent.family
      matches[orcid_given] = orcid_id
      matches[orcid_credit] = orcid_id
    end
    agent.orcid_identifier = matches[agent.fullname] || matches[agent.given]
  end

  def self.populate_profiles
    count = 0
    agents = Agent.where.not(orcid_identifier: nil)
    pbar = ProgressBar.new("Profiles", agents.count)

    agents.find_each do |agent|
      count += 1
      pbar.set(count)

      next if agent.processed_profile
      response = RestClient::Request.execute(
        method: :get,
        url: Sinatra::Application.settings.orcid_api_url + agent.orcid_identifier + '/orcid-profile',
        headers: { accept: 'application/orcid+json' }
      )
      parse_profile_orcid_response(agent, response)
      agent.processed_profile = true
      agent.save!
    end

    pbar.finish
  end

  def self.rebuild_gender_hash
    if Agent::GENDER_HASH.empty?
      Agent.where.not(gender: nil).pluck(:given, :gender).uniq.each do |a|
        Agent::GENDER_HASH[a[0].split.first] = a[1]
      end
    end
  end

  # Using data from https://github.com/guydavis/babynamemap/blob/master/db.sql.gz
  def self.search_gender
    count = 0
    agents = Agent.where("length(given) > 1", gender: nil)
    pbar = ProgressBar.new("Genders", agents.count)

    agents.find_each do |a|
      count += 1
      pbar.set(count)

      first_name = a.given.split.first.strip
      next if first_name.include? "."
      gender = Agent::GENDER_HASH[first_name]
      unless gender
        searched = BabyName.where("name = %s" % BabyName.connection.quote(first_name))
                           .pluck(:gender, :is_popular, :rating_avg)
                           .map{ |n| { gender: n[0], is_popular: n[1], rating_avg: n[2].nil? ? 0 : n[2] } }

        if searched.length == 1
          gender = searched.first[:gender]
        end
        if searched.length > 1
          num_popular = searched.map{ |p| p[:is_popular] ? true : nil }.compact.size
          if num_popular == 1
            gender = searched.sort_by{ |p| p[:is_popular] ? 0 : 1 }.first[:gender]
          end
          if num_popular > 1
            if searched.map{|r| r[:rating_avg]}.uniq.size > 1
              gender = searched.sort_by{ |r| r[:rating_avg] }.reverse.first[:gender]
            end
          end
        end

        Agent::GENDER_HASH[first_name] = gender if gender
        gender = "male" if a.given.downcase.include?("frère")
        gender = "male" if a.given.downcase.include?("brother")
        gender = "female" if a.given.downcase.include?("soeur")
      end

      if gender
        a.gender = gender
        a.save!
      end

    end

    pbar.finish
  end

  def self.parse_profile_orcid_response(agent, response)

    Agent.transaction do
      AgentWork.delete_all(agent_id: agent.id)
      profile = JSON.parse(response, :symbolize_names => true)[:"orcid-profile"]
      agent.email = profile[:"orcid-bio"][:"contact-details"][:email][0][:value] rescue nil
      agent.position = profile[:"orcid-activities"][:affiliations][:affiliation][0][:"role-title"] rescue nil
      agent.affiliation = profile[:"orcid-activities"][:affiliations][:affiliation][0][:organization][:name] rescue nil

      publications = profile[:"orcid-activities"][:"orcid-works"][:"orcid-work"] rescue []
      publications.each do |pub|
        identifiers = pub[:"work-external-identifiers"][:"work-external-identifier"] rescue []
        identifiers.each do |identifier|
            if identifier[:"work-external-identifier-type"] == "DOI"
              doi = Collector::AgentUtility.doi_clean(identifier[:"work-external-identifier-id"][:value])
              work = Work.where(doi: doi).first_or_create
              AgentWork.create(agent_id: agent.id, work_id: work.id)
              break
            end
        end
      end
    end

  end

  def fullname
    [given, family].join(" ").strip
  end

  def determinations_institutions
    determinations.map{|o| o.institutionCode }.uniq
  end

  def recordings_institutions
    recordings.map{|o| o.institutionCode }.uniq
  end

  def determinations_year_range
    years = determinations.pluck(:dateIdentified)
                          .map{ |d| Collector::AgentUtility.valid_year(d) }
                          .compact
                          .minmax rescue [nil,nil]
    years[0] = years[1] if years[0].nil?
    years[1] = years[0] if years[1].nil?
    Range.new(years[0], years[1])
  end

  def recordings_year_range
    years = recordings.pluck(:eventDate)
                      .map{ |d| Collector::AgentUtility.valid_year(d) }
                      .compact
                      .minmax rescue [nil,nil]
    years[0] = years[1] if years[0].nil?
    years[1] = years[0] if years[1].nil?
    Range.new(years[0], years[1])
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

  def network
    network = Collector::AgentNetwork.new(id)
    network.build
    network.to_vis
  end

end
class Agent < ActiveRecord::Base
  has_many :determinations, :through => :occurrence_determiners, :source => :occurrence
  has_many :occurrence_determiners

  has_many :recordings, :through => :occurrence_recorders, :source => :occurrence  
  has_many :occurrence_recorders

  has_many :determined_taxa, :through => :taxon_determiners, :source => :taxon
  has_many :taxon_determiners

  has_many :works, :through => :agent_works
  has_many :agent_works

  def self.populate_orcids
    search_orcid
  end

  def self.search_orcid
    Agent.where("orcid_matches IS NULL").find_each do |agent|
      agent.orcid_matches = 0
      if !agent.family.empty? && !agent.given.empty?
        max_year = [agent.determinations_year_range[1], agent.recordings_year_range[1]].compact.max
        if !max_year.nil? && max_year >= 1950
          search = 'family-name:' + URI::encode(agent.family) + '+AND+given-names:' + URI::encode(agent.given)
          response = RestClient::Request.execute(
            method: :get,
            url: Collector::Config.orcid_base_url + 'search/orcid-bio?q=' + search,
            headers: { accept: 'application/orcid+json' }
          )
          parse_orcid_response(agent, response)
        end
      end
      agent.save!
    end
  end

  def self.parse_orcid_response(agent, response)
    hits = JSON.parse(response, :symbolize_names => true)[:"orcid-search-results"][:"orcid-search-result"] rescue []
    agent.orcid_matches = hits.length
    found = hits.length > 0 ? " ... found " + hits.length.to_s : ""
    agent.orcid_identifier = hits[0][:"orcid-profile"][:"orcid-identifier"][:path] if hits.length == 1
    puts "Searched orcid for " + agent.family + ", " + agent.given + found
  end

  def determinations_year_range
    years = determinations.select("dateIdentified").collect{ |d| Date.strptime(d.dateIdentified, "%Y").year rescue nil }.compact.minmax rescue [nil,nil]
    years[0] = years[1] if years[0].nil?
    years[1] = years[0] if years[1].nil?
    years
  end

  def recordings_year_range
    years = recordings.select("eventDate").collect{ |d| Date.strptime(d.eventDate, "%Y").year rescue nil }.compact.minmax rescue [nil,nil]
    years[0] = years[1] if years[0].nil?
    years[1] = years[0] if years[1].nil?
    years
  end

  def recordings_coordinates
    recordings.select("decimalLatitude,decimalLongitude").collect{ |c| [c.decimalLongitude.to_f, c.decimalLatitude.to_f] }.compact.uniq
  end

  def recordings_with
    occurrence_ids = occurrence_recorders.select("occurrence_id").collect{ |o| o.occurrence_id }
    return [] if occurrence_ids.empty?
    OccurrenceRecorder.select("agent_id, family, given")
                                .joins("JOIN agents ON occurrence_recorders.agent_id = agents.id")
                                .where(occurrence_id: occurrence_ids)
                                .where.not(agent_id: id)
                                .map{ |a| { id: a.agent_id, given: a.given, family: a.family } }
                                .uniq
                                .sort_by { |a| a[:family] }
  end

  def determined_species
    parser = ScientificNameParser.new
    determinations.select("scientificName").collect{ |c| c.scientificName }.compact.uniq.map{ |s| parser.parse(s)[:scientificName][:canonical] rescue s }
  end

  def determined_families
    determined_taxa.select("family").map{ |f| f.family }.uniq
  end

end
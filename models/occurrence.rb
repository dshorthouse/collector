class Occurrence < ActiveRecord::Base
  has_many :determiners, :through => :occurrence_determiners, :source => :agent
  has_many :occurrence_determiners

  has_many :recorders, :through => :occurrence_recorders, :source => :agent
  has_many :occurrence_recorders

  has_many :taxa, :through => :taxon_occurrences, :source => :taxon
  has_many :taxon_occurrences

  def self.populate_data(infile)
    # data file downloaded and extracted from http://data.canadensys.net
    sql = "LOAD DATA LOCAL INFILE '#{infile}' 
           INTO TABLE occurrences 
           FIELDS TERMINATED BY '\t' 
           LINES TERMINATED BY '\n' 
           IGNORE 1 LINES"
    Occurrence.connection.execute(sql)
  end

  def self.populate_agents
    parse_determiners
    parse_recorders
  end

  def self.populate_taxa
    parse_taxa
  end

  def self.parse_determiners
    count = 0
    Occurrence.where("identifiedBy IS NOT NULL").find_each do |o|
      count += 1

      determiners = Collector::AgentUtility.explode_names(o.identifiedBy)
      determiners.each do |d|
        name = Namae.parse d
        cleaned_name = Collector::AgentUtility.clean_namae(name)
        save_agent(cleaned_name, o.id, "determiner")
      end

      puts "Parsed %s occurrences for determiners" % count if count % 1000 == 0

    end
  end

  def self.parse_recorders
    count = 0
    Occurrence.where("recordedBy IS NOT NULL").find_each do |o|
      count += 1

      recorders = Collector::AgentUtility.explode_names(o.recordedBy)
      recorders.each do |r|
        name = Namae.parse r
        cleaned_name = Collector::AgentUtility.clean_namae(name)
        save_agent(cleaned_name, o.id, "recorder")
      end

      puts "Parsed %s occurrences for recorders" % count if count % 1000 == 0

    end
  end

  def self.parse_taxa
    count = 0
    Occurrence.where("identifiedBy IS NOT NULL AND family <> ''").find_each do |o|
      count += 1

      Occurrence.transaction do
        taxon = Taxon.find_or_create_by(family: o.family)
        TaxonOccurrence.create(taxon_id: taxon.id, occurrence_id: o.id)

        o.occurrence_determiners.each do |d|
          save_taxon_determiner(taxon.id, d.agent_id)
        end
      end

      puts "Parsed %s occurrences for taxa" % count if count % 1000 == 0
    end
  end

  def self.save_agent(name, id, type)
    return if name.family.nil? || name.family.length < 3

    family = name.family.to_s
    given = name.given.to_s

    Occurrence.transaction do
      agent = Agent.find_or_create_by(family: family, given: given)
      if agent.canonical_id.nil?
        agent.update(canonical_id: agent.id)
      end
      if type == "determiner"
        OccurrenceDeterminer.create(occurrence_id: id, agent_id: agent.id)
      end
      if type == "recorder"
        OccurrenceRecorder.create(occurrence_id: id, agent_id: agent.id)
      end
    end
  end

  def self.save_taxon_determiner(taxon_id, agent_id)
    return if taxon_id.nil? || agent_id.nil?
    TaxonDeterminer.create(taxon_id: taxon_id, agent_id: agent_id)
  end

  def coordinates
    return [] if decimalLatitude.presence.nil? || decimalLongitude.presence.nil?
    [decimalLongitude.to_f, decimalLatitude.to_f]
  end

  def agents
    response = Occurrence.connection.select_all("
      SELECT
        d.agent_id as determiner, null as recorder 
      FROM 
        occurrences o JOIN occurrence_determiners d on d.occurrence_id = o.id 
      WHERE 
        o.id = %s 
      UNION ALL 
      SELECT 
        null as determiner, r.agent_id as recorder 
      FROM 
        occurrences o JOIN occurrence_recorders r on r.occurrence_id = o.id 
      WHERE 
        o.id = %s" % [id,id])
    { determiners: response.map{|d| d["determiner"]}.compact, recorders: response.map{|r| r["recorder"]}.compact }
  end

end
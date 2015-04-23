class Occurrence < ActiveRecord::Base
  has_many :determiners, :through => :occurrence_determiners, :source => :agent
  has_many :occurrence_determiners

  has_many :recorders, :through => :occurrence_recorders, :source => :agent
  has_many :occurrence_recorders

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

      determiners = Collector::Utility.explode_names(o.identifiedBy)
      determiners.each do |d|
        name = Namae.parse d
        cleaned_name = Collector::Utility.clean_namae(name)
        save_agent(cleaned_name, o.id, "determiner")
      end

      puts "Parsed %s occurrences for determiners" % count if count % 1000 == 0

    end
  end

  def self.parse_recorders
    count = 0
    Occurrence.where("recordedBy IS NOT NULL").find_each do |o|
      count += 1

      recorders = Collector::Utility.explode_names(o.recordedBy)
      recorders.each do |c|
        name = Namae.parse c
        cleaned_name = Collector::Utility.clean_namae(name)
        save_agent(cleaned_name, o.id, "recorder")
      end

      puts "Parsed %s occurrences for recorders" % count if count % 1000 == 0

    end
  end

  def self.parse_taxa
    count = 0
    Occurrence.where("identifiedBy IS NOT NULL AND family <> ''").find_each do |o|
      count += 1

      o.occurrence_determiners.each do |d|
        save_taxon(o.family, d.agent_id)
      end

      puts "Parsed %s occurrences for taxa" % count if count % 1000 == 0
    end
  end

  def self.save_agent(name, id, type)

    return if name.family.nil? || name.family.length < 3

    agent_id = nil
    family = name.family.to_s
    given = name.given.to_s

    Occurrence.transaction do
      agent_id = Occurrence.connection.select_value("SELECT id FROM agents WHERE family = %s and given = %s" % [Occurrence.connection.quote(family), Occurrence.connection.quote(given)])
      unless agent_id
        Occurrence.connection.execute("INSERT INTO agents (family, given) VALUES (%s, %s)" % [Occurrence.connection.quote(family), Occurrence.connection.quote(given)])
        agent_id = Occurrence.connection.select_values("SELECT last_insert_id()")[0]
      end
      if type == "determiner"
        Occurrence.connection.execute("INSERT INTO occurrence_determiners (occurrence_id, agent_id) VALUES (%s, %s)" % [id, agent_id])
      end
      if type == "recorder"
        Occurrence.connection.execute("INSERT INTO occurrence_recorders (occurrence_id, agent_id) VALUES (%s, %s)" % [id, agent_id])
      end
    end
  end

  def self.save_taxon(family, agent_id)

    return if family.nil? || agent_id.nil?

    family_id = nil

    Occurrence.transaction do
      family_id = Occurrence.connection.select_value("SELECT id FROM taxa WHERE family = %s" % [Occurrence.connection.quote(family)])
      unless family_id
        Occurrence.connection.execute("INSERT INTO taxa (family) VALUES (%s)" % [Occurrence.connection.quote(family)])
        family_id = Occurrence.connection.select_values("SELECT last_insert_id()")[0]
      end
      Occurrence.connection.execute("INSERT INTO taxon_determiners (taxon_id, agent_id) VALUES (%s, %s)" % [family_id, agent_id])
    end
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
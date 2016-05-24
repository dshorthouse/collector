class Occurrence < ActiveRecord::Base
  has_many :determiners, :through => :occurrence_determiners, :source => :agent
  has_many :occurrence_determiners

  has_many :recorders, :through => :occurrence_recorders, :source => :agent
  has_many :occurrence_recorders

  has_many :taxa, :through => :taxon_occurrences, :source => :taxon
  has_many :taxon_occurrences

  def self.populate_agents
    @redis = Redis.new(db: 1)
    @redis.flushdb

    @recorders = File.open("/tmp/recorders", "w")
    @determiners = File.open("/tmp/determiners", "w")

    occurrences = Occurrence.pluck(:id, :recordedBy, :identifiedBy)
    Parallel.map(occurrences.in_groups_of(1000, false), progress: "Agents") do |batch|
      batch.each do |o|
        next if o[1].nil? && o[2].nil?

        if o[1] == o[2]
          save_agents(parse_agents(o[1]), o[0], ["recorder", "determiner"])
        elsif o[2].nil?
          save_agents(parse_agents(o[1]), o[0], ["recorder"])
        elsif o[1].nil?
          save_agents(parse_agents(o[2]), o[0], ["determiner"])
        else
          save_agents(parse_agents(o[1]), o[0], ["recorder"])
          save_agents(parse_agents(o[2]), o[0], ["determiner"])
        end
      end
    end

    Agent.update_all("canonical_id = id")

    [@recorders,@determiners].each do |file|
      sql = "LOAD DATA INFILE '#{file.path}' 
             INTO TABLE occurrence_#{File.basename(file)} 
             FIELDS TERMINATED BY ',' 
             LINES TERMINATED BY '\n' 
             (occurrence_id, agent_id)"
      Occurrence.connection.execute sql
      file.close
      File.unlink(file)
    end

    @redis.flushdb
  end

  def self.parse_agents(namestring)
    names = []
    Collector::AgentUtility.parse(namestring).each do |r|
      name = Collector::AgentUtility.clean(r)
      if !name[:family].nil? && name[:family].length >= 3
        names << name
      end
    end
    names.uniq
  end

  def self.save_agents(names, id, roles)
    names.each do |name|
      family = name[:family].to_s
      given = name[:given].to_s
      fullname = [given, family].join(" ").strip
      agent_id = @redis.get(fullname)

      if !agent_id
        begin
          agent = Agent.find_or_create_by(family: family, given: given)
          agent_id = agent.id
          @redis.set(agent.fullname, agent_id)
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      roles.each do |role|
        if role == "recorder"
          @recorders.write([id,agent_id].join(",")+"\n")
        end
        if role == "determiner"
          @determiners.write([id,agent_id].join(",")+"\n")
        end
      end
    end
  end

  def self.populate_taxa
    @redis = Redis.new(db: 1)
    @redis.flushdb

    @taxon_occurrences = File.open("/tmp/taxon_occurrences", "w")
    @taxon_determiners = File.open("/tmp/taxon_determiners", "w")

    taxa = Occurrence.where.not(identifiedBy: [nil, ''], family: [nil,'']).pluck(:id, :family)
    Parallel.map(taxa.in_groups_of(1000, false), progress: "Taxa") do |batch|
      batch.each do |o|
        taxon_id = @redis.get(o[1])
        if taxon_id.nil?
          begin
            taxon = Taxon.find_or_create_by(family: o[1])
            taxon_id = taxon.id
            @redis.set(o[1], taxon_id)
          rescue ActiveRecord::RecordNotUnique
            retry
          end
        end
        @taxon_occurrences.write([o[0],taxon_id].join(",")+"\n")
        OccurrenceDeterminer.where(occurrence_id: o[0]).pluck(:agent_id).each do |od|
          @taxon_determiners.write([od,taxon_id].join(",")+"\n")
        end
      end
    end

    sql = "LOAD DATA INFILE '#{@taxon_occurrences.path}' 
           INTO TABLE #{File.basename(@taxon_occurrences)}
           FIELDS TERMINATED BY ',' 
           LINES TERMINATED BY '\n' 
           (occurrence_id, taxon_id)"
    Occurrence.connection.execute sql

    sql = "LOAD DATA INFILE '#{@taxon_determiners.path}' 
           INTO TABLE #{File.basename(@taxon_determiners)}
           FIELDS TERMINATED BY ',' 
           LINES TERMINATED BY '\n' 
           (agent_id, taxon_id)"
    Occurrence.connection.execute sql

    [@taxon_occurrences,@taxon_determiners].each do |file|
      file.close
      File.unlink(file)
    end

    @redis.flushdb
  end

  def coordinates
    lat = decimalLatitude.to_f
    long = decimalLongitude.to_f
    return nil if lat == 0 || long == 0 || lat > 90 || lat < -90 || long > 180 || long < -180
    [long, lat]
  end

  def agents
    response = Occurrence.connection.select_all("
      SELECT
        d.agent_id as determiner, null as recorder, a.given, a.family
      FROM 
        occurrences o 
      JOIN occurrence_determiners d ON d.occurrence_id = o.id 
      JOIN agents a ON d.agent_id = a.id
      WHERE 
        o.id = %s 
      UNION ALL 
      SELECT 
        null as determiner, r.agent_id as recorder, a.given, a.family
      FROM 
        occurrences o 
      JOIN occurrence_recorders r ON r.occurrence_id = o.id 
      JOIN agents a ON r.agent_id = a.id
      WHERE 
        o.id = %s" % [id,id])
    { 
      determiners: response.map{|d| { id: d["determiner"], given: d["given"], family: d["family"] } if d["determiner"]}.compact, 
      recorders: response.map{|r|  { id: r["recorder"], given: r["given"], family: r["family"] } if r["recorder"]}.compact
    }
  end

end
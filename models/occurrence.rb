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

    pbar = ProgressBar.create(title: "Agents", total: Occurrence.count, autofinish: false, format: '%t %b>> %i| %e')

    Occurrence.find_in_batches(batch_size: 2000) do |batches|
      batches.each do |o|
        pbar.increment
        next if o.identifiedBy.nil? && o.recordedBy.nil?

        if o.recordedBy == o.identifiedBy
          save_agents(parse_agents(o.recordedBy), o.id, ["recorder", "determiner"])
        elsif o.identifiedBy.nil?
          save_agents(parse_agents(o.recordedBy), o.id, ["recorder"])
        elsif o.recordedBy.nil?
          save_agents(parse_agents(o.identifiedBy), o.id, ["determiner"])
        else
          save_agents(parse_agents(o.recordedBy), o.id, ["recorder"])
          save_agents(parse_agents(o.identifiedBy), o.id, ["determiner"])
        end
      end
    end
    pbar.finish

    Agent.update_all("canonical_id = id")
    @redis.flushdb
    pbar.finish
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
        #accommodate potential race conditions with a rescue
        begin
          agent = Agent.find_or_create_by(family: family, given: given)
          agent_id = agent.id
          @redis.set(agent.fullname, agent_id)
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      roles.each do |role|
        "Occurrence#{role.capitalize}".constantize.create(occurrence_id: id, agent_id: agent_id)
      end
    end
  end

  def self.populate_taxa
    taxa = Occurrence.where.not(identifiedBy: [nil, ''], family: [nil,''])
    pbar = ProgressBar.create(title: "Taxa", total: taxa.count, autofinish: false, format: '%t %b>> %i| %e')
    taxa.find_each do |o|
      pbar.increment

      Occurrence.transaction do
        taxon = Taxon.where(family: o.family).first_or_create
        TaxonOccurrence.create(taxon_id: taxon.id, occurrence_id: o.id)

        o.occurrence_determiners.each do |d|
          save_taxon_determiner(taxon.id, d.agent_id)
        end
      end
    end
    pbar.finish
  end

  def self.save_taxon_determiner(taxon_id, agent_id)
    return if taxon_id.nil? || agent_id.nil?
    TaxonDeterminer.find_or_create_by(taxon_id: taxon_id, agent_id: agent_id)
  end

  def coordinates
    return [] if decimalLatitude.presence.nil? || decimalLongitude.presence.nil?
    [decimalLongitude.to_f, decimalLatitude.to_f]
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
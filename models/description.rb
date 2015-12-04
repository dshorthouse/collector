class Description < ActiveRecord::Base
  has_many :agents, :through => :agent_descriptions
  has_many :agent_descriptions

  def self.populate_agents
    count = 0
    parser = ScientificNameParser.new
    Occurrence.where("typeStatus LIKE '%type'").pluck(:scientificName).uniq.each do |namestring|
      count += 1
      authors = []
      year = nil

      parsed_scientific_name = parser.parse(namestring.gsub(/\A"|"\Z/, ''))[:scientificName] rescue nil
      normalized_scientific_name = parsed_scientific_name[:normalized] rescue nil

      if !normalized_scientific_name.nil?
        authors_year = description_authors(parsed_scientific_name)
        Description.transaction do
          description = Description.find_or_create_by(scientificName: normalized_scientific_name, year: authors_year[:year])
          authors_year[:authors].uniq.each do |d|
            name = Collector::AgentUtility.parse(d)
            cleaned_name = Collector::AgentUtility.clean(name[0])
            if !cleaned_name.family.nil?
              agent = Agent.find_or_create_by(family: cleaned_name.family.to_s, given: cleaned_name.given.to_s)
              if agent.canonical_id.nil?
                agent.update(canonical_id: agent.id)
              end
              AgentDescription.find_or_create_by(description_id: description.id, agent_id: agent.id)
            end
          end
        end
      end

      puts "Parsed %s occurrences for describers" % count if count % 10 == 0

    end
  end

  def self.description_authors(parsed_scientific_name)
    authors = []
    year = nil
    if parsed_scientific_name[:details][0].has_key?(:species) && parsed_scientific_name[:details][0][:species].has_key?(:basionymAuthorTeam)
      year = parsed_scientific_name[:details][0][:species][:basionymAuthorTeam][:year] rescue nil
      authors = parsed_scientific_name[:details][0][:species][:basionymAuthorTeam][:author] rescue []
    elsif parsed_scientific_name[:details][0].has_key?(:infraspecies) && parsed_scientific_name[:details][0][:infraspecies][0].has_key?(:basionymAuthorTeam)
      year = parsed_scientific_name[:details][0][:infraspecies][0][:basionymAuthorTeam][:year] rescue nil
      authors = parsed_scientific_name[:details][0][:infraspecies][0][:basionymAuthorTeam][:author] rescue []
    end
    { authors: authors, year: year }
  end

end
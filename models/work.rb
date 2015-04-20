class Work < ActiveRecord::Base
  has_many :agents, :through => :agent_works
  has_many :agent_works

  def self.populate_works
    Agent.joins("LEFT JOIN agent_works on agents.id = agent_works.agent_id").where("agent_works.agent_id IS NULL").where("agents.orcid_matches = 1").find_each do |agent|
      next if agent.works.length > 0 || agent.processed_works
      response = RestClient::Request.execute(
        method: :get,
        url: Collector::Config.orcid_base_url + agent.orcid_identifier + '/orcid-works',
        headers: { accept: 'application/orcid+json' }
      )
      parse_orcid_response(agent, response)
    end
  end

  def self.parse_orcid_response(agent, response)
    Work.transaction do
      has_pub = false
      publications = JSON.parse(response, :symbolize_names => true)[:"orcid-profile"][:"orcid-activities"][:"orcid-works"][:"orcid-work"] rescue []
      publications.each do |pub|
        identifiers = pub[:"work-external-identifiers"][:"work-external-identifier"] rescue []
        identifiers.each do |identifier|
            if identifier[:"work-external-identifier-type"] == "DOI"
              has_pub = true
              doi = identifier[:"work-external-identifier-id"][:value]
              work_id = Work.connection.select_value("SELECT id FROM works WHERE doi = %s" % Work.connection.quote(doi))
              unless work_id
                work = Work.new
                work.doi = identifier[:"work-external-identifier-id"][:value]
                work.save!
                work_id = work.id
              end
              Work.connection.execute("INSERT INTO agent_works (agent_id, work_id) VALUES (%s, %s)" % [agent.id, work_id])
              break
            end
        end
      end
      puts "Added publications for " + agent.family + ", " + agent.given if has_pub
      puts "Nothing for " + agent.family + ", " + agent.given if !has_pub
      
      agent.processed_works = true
      agent.save!
    end
  end

  def self.populate_citations
    Work.where("processed IS NULL").find_each do |w|
      response = RestClient::Request.execute(
        method: :get,
        url: "http://crosscite.org/citeproc/format?style=entomologia-experimentalis-et-applicata&lang=en-US&doi=" + w.doi
      ) rescue nil
      w.citation = response
      w.processed = true
      w.save!
      puts "Added citation for " + w.id.to_s
    end
  end

end
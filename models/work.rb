class Work < ActiveRecord::Base
  has_many :agents, :through => :agent_works
  has_many :agent_works

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
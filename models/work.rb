class Work < ActiveRecord::Base
  has_many :agents, :through => :agent_works
  has_many :agent_works

  def self.populate_citations
    count = 0
    works = Work.where(processed: nil)
    pbar = ProgressBar.new("Works", works.count)

    works.find_each do |w|
      count += 1
      pbar.set(count)
      response = RestClient::Request.execute(
        method: :get,
        url: "http://crosscite.org/citeproc/format?style=entomologia-experimentalis-et-applicata&lang=en-US&doi=" + w.doi
      ) rescue nil
      w.citation = response
      w.processed = true
      w.save!
    end

    pbar.finish
  end

end
class Work < ActiveRecord::Base
  has_many :agents, :through => :agent_works
  has_many :agent_works

  def self.populate_citations
    works = Work.where(processed: nil)
    pbar = ProgressBar.create(title: "Works", total: works.count, autofinish: false, format: '%t %b>> %i| %e')

    works.find_each do |w|
      pbar.increment
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
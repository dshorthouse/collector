class Dataset < ActiveRecord::Base

  def self.populate_datasets
    datasets = Agent.where("id = canonical_id AND processed_datasets IS NULL").where.not(given: [nil,''])
    pbar = ProgressBar.new("Datasets", datasets.count)

    datasets.find_each do |agent|
      count += 1
      pbar.set(count)

      search = 'contributor:' + URI::encode(agent.fullname)
      response = send_datacite_request(search)
      if response[:numFound] > 0
        datasets = datacite_records(response)
        total_pages = response[:numFound]/1000.to_f
        if total_pages > 1
          (1..total_pages.to_i).first(3).each do |page|
            response = send_datacite_request(search, page*1000+1)
            datacite_records(response).each do |record|
              datasets << record
            end
          end
        end
        save_datasets(agent, datasets.compact)
      end
      agent.processed_datasets = true
      agent.save!
    end

    pbar.finish
  end

  def self.send_datacite_request(search, start = 0)
    url = Sinatra::Application.settings.datacite_api_url + '?wt=json&fl=doi,title&rows=1000&start=' + start.to_s + '&q=' + search
    response = RestClient::Request.execute(
      method: :get,
      url: url
    )
    JSON.parse(response, :symbolize_names => true)[:response]
  end

  def self.datacite_records(response)
    response[:docs]
  end

  def self.save_datasets(agent, datasets)
    Dataset.transaction do
      datasets.each do |d|
        dataset = Dataset.create_with(title: d[:title][0]).find_or_create_by(doi: d[:doi])
        AgentDataset.create(agent_id: agent.id, dataset_id: dataset.id)
      end
    end
  end

end
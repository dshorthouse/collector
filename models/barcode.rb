class Barcode < ActiveRecord::Base

  def self.populate_barcodes
    search_barcodes
  end

  def self.search_barcodes
    Agent.where("given <> ''").where(processed_barcodes: nil).find_each do |agent|
      name = agent.given + " " + agent.family
      puts agent.id.to_s + ": " + name
      params = {
        :params => {
          :researchers => name,
          :format => 'xml' 
        }
      }
      RestClient.get(Sinatra::Application.settings.bold_api_url, params) do |response, request, result, &block|
        xml = Nokogiri::XML.parse(response)
        xml.xpath("//record").each do |record|
          processid = nil
          bin_uri = nil
          catalognum = nil
          record.children.each do |element|
            if element.name == 'processid'
              processid = element.text
            end
            if element.name == 'bin_uri'
              bin_uri = element.text
            end
            if element.name == 'specimen_identifiers'
              element.children.each do |sid|
                if sid.name == 'catalognum'
                  catalognum = sid.text
                end
              end
            end
          end
          if processid
            Barcode.transaction do
              barcode = Barcode.create_with(bin_uri: bin_uri, catalognum: catalognum).find_or_create_by(processid: processid)
              AgentBarcode.create(agent_id: agent.id, barcode_id: barcode.id)
            end
          end
        end
      end
      agent.processed_barcodes = true
      agent.save!
      puts "\t\t...done"

    end
  end

end
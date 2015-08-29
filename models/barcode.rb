class Barcode < ActiveRecord::Base

  def self.populate_barcodes
    search_barcodes
  end

  def self.search_barcodes
    Agent.where("given <> ''").where(processed_barcodes: nil).find_each do |agent|
      barcodes = []
      name = agent.given + " " + agent.family
      puts agent.id.to_s + ": " + name

      params = {
        :researchers => name,
        :format => 'xml'
      }
      url = [Sinatra::Application.settings.bold_api_url, "?", URI.encode_www_form(params)].join

      response = RestClient::Request.execute(method: :get, url: url, timeout: 9000000)
      xml = Nokogiri::XML.parse(response)
      xml.xpath("//record").each do |record|
        processid = nil
        bin_uri = nil
        catalognum = nil
        record.children.each do |element|
          processid = element.text if element.name == 'processid'
          bin_uri = element.text if element.name == 'bin_uri'
          if element.name == 'specimen_identifiers'
            element.children.each do |sid|
              catalognum = sid.text if sid.name == 'catalognum'
            end
          end
        end
        barcodes << { processid: processid, bin_uri: bin_uri, catalognum: catalognum } if processid
      end

      Barcode.transaction do
        barcodes.each do |b|
          barcode = Barcode.create_with(bin_uri: b[:bin_uri], catalognum: b[:catalognum]).find_or_create_by(processid: b[:processid])
          AgentBarcode.create(agent_id: agent.id, barcode_id: barcode.id)
        end
        agent.processed_barcodes = true
        agent.save!
        puts "\t\t...done"
      end

    end
  end

end
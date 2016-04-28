class Barcode < ActiveRecord::Base

  def self.populate_barcodes
    count = 0
    barcodes = Agent.where("id = canonical_id AND processed_barcodes IS NULL").where.not(given: [nil,''])
    pbar = ProgressBar.new("Barcodes", barcodes.count)

    barcodes.find_each do |agent|
      count += 1
      pbar.set(count)

      barcodes = []
      tmp_file = "/tmp/%s.xml" % agent.id

      params = {
        :researchers => agent.fullname,
        :format => 'xml'
      }

      url = URI(Sinatra::Application.settings.bold_api_url)

      Net::HTTP.start(url.host.downcase) do |http|
        resp = http.get([url.path, URI.encode_www_form(params)].join("?"))
        open(tmp_file, "wb") do |file|
          file.write(resp.body)
        end
      end

      file_size = File.stat(tmp_file).size

      if file_size > 0 && file_size < 20000000
        xml = Nokogiri::XML.parse(File.open(tmp_file))
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
      end

      File.delete(tmp_file)

      Barcode.transaction do
        barcodes.each do |b|
          barcode = Barcode.create_with(bin_uri: b[:bin_uri], catalognum: b[:catalognum]).find_or_create_by(processid: b[:processid])
          AgentBarcode.find_or_create_by(agent_id: agent.id, barcode_id: barcode.id)
        end
        agent.processed_barcodes = true
        agent.save!
      end

    end

    pbar.finish
  end

end
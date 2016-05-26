class Taxon < ActiveRecord::Base
  has_many :determinations, through: :taxon_determiners, source: :agent
  has_many :taxon_determiners

  has_many :occurrences, through: :taxon_occurrences, source: :occurrence
  has_many :taxon_occurrences

  def self.populate_metadata
    Parallel.map(Taxon.find_each, progress: "Metadata") do |t|
      response = RestClient::Request.execute(
        method: :get,
        url: Sinatra::Application.settings.eol_api + 'search/1.0.json?exact=true&q=' + URI::encode(t.family),
      )
      parse_search_eol_response(t, response)
    end
  end

  def self.parse_search_eol_response(taxon, response)
    results = JSON.parse(response, :symbolize_names => true)
    id = results[:results][0][:id] rescue nil
    if !id.nil?
      response = RestClient::Request.execute(
        method: :get,
        url: Sinatra::Application.settings.eol_api + 'pages/1.0/' + id.to_s + '.json?common_names=true&images=1&&details=true&videos=0&sounds=0&maps=0&text=0'
      ) rescue nil
      parse_page_eol_response(taxon, response) if !response.nil?
    end
  end

  def self.parse_page_eol_response(taxon, response)
    results = JSON.parse(response, :symbolize_names => true)
    common = nil
    image = nil
    results[:vernacularNames].each do |vn|
      if vn[:language] == "en" && vn[:eol_preferred]
        common = vn[:vernacularName]
        break
      end
    end
    if results[:dataObjects].length > 0 && results[:dataObjects][0][:dataType] == "http://purl.org/dc/dcmitype/StillImage"
      image = results[:dataObjects][0].to_json
    end
    taxon.common = common
    taxon.image = image
    taxon.save
  end

  def image_data
    content = JSON.parse(image, :symbolize_names => true) rescue nil
    return if content.nil?
    { mediaURL: content[:eolMediaURL], license: content[:license], rightsHolder: content[:rightsHolder], source: content[:source] }
  end

  def occurrence_coordinates
    occurrences.map(&:coordinates).uniq.compact
  end

end
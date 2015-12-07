class Taxon < ActiveRecord::Base
  has_many :determinations, :through => :taxon_determiners, :source => :agent
  has_many :taxon_determiners

  has_many :occurrences, :through => :taxon_occurrences, :source => :occurrence
  has_many :taxon_occurrences

  def self.populate_metadata
    Taxon.find_each do |t|
      eol_metadata(t)
      gn_hierarchies(t)
    end
  end

  def self.eol_metadata(t)
    response = RestClient::Request.execute(
      method: :get,
      url: Sinatra::Application.settings.eol_api + 'search/1.0.json?exact=true&q=' + URI::encode(t.family),
    )
    parse_search_eol_response(t, response)
  end

  def self.gn_hierarchies(t)
    response = RestClient::Request.execute(
      method: :get,
      url: Sinatra::Application.settings.gn_api + 'name_resolvers.json?preferred_data_sources=1&names=' + URI::encode(t.family)
    )
    parse_gn_response(t,response)
  end

  def self.parse_search_eol_response(taxon, response)
    results = JSON.parse(response, :symbolize_names => true)
    id = results[:results][0][:id] rescue nil
    if !id.nil?
      response = RestClient::Request.execute(
        method: :get,
        url: Sinatra::Application.settings.eol_api + 'pages/1.0/' + id.to_s + '.json?common_names=true&images=1&&details=true&videos=0&sounds=0&maps=0&text=0'
      )
      parse_page_eol_response(taxon, response)
    end
  end

  def self.parse_gn_response(taxon,response)
    results = JSON.parse(response, :symbolize_names => true)
    path = results[:data][0][:results][0][:classification_path].split("|") rescue []
    path_ranks = results[:data][0][:results][0][:classification_path_ranks] rescue ""
    if path.size == 5 && path_ranks == "kingdom|phylum|class|order|family"
      taxon.kingdom = path[0]
      taxon.phylum = path[1]
      taxon._class = path[2]
      taxon._order = path[3]
      taxon.save
    end
    puts "Finished #{taxon.id}, #{taxon.family}"
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
    puts !common.nil? ? [taxon.family, common].join(": ") : taxon.family
  end

  def image_data
    content = JSON.parse(image, :symbolize_names => true) rescue nil
    return if content.nil?
    { mediaURL: content[:eolMediaURL], license: content[:license], rightsHolder: content[:rightsHolder], source: content[:source] }
  end

  def occurrence_coordinates
    occurrences.pluck(:decimalLongitude, :decimalLatitude)
              .compact.uniq
              .map{ |c| [c[0].to_f, c[1].to_f] }
  end

end
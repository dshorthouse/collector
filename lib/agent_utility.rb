# encoding: utf-8

module Collector
  module AgentUtility

    STRIP_OUT = %r{
      \b\d+\(?(?i:[[:alpha:]])\)?\b|
      \b[,;]?\s*(?i:et\s+al)\.?|
      \bu\.\s*a\.|
      \b[,;]?\s*(?i:and|&)?\s*(?i:others)\s*\b|
      \b[,;]?\s*(?i:etc)\.?|
      \b[,;]?\s*(?i:on)\b|
      \b[,;]?\s*(?i:unkn?own)\b|
      \b[,;]?\s*(?i:n/a)\b|
      \b[,;]?\s*(?i:ann?onymous)\b|
      \b[,;]?\s*(?i:undetermined|indeterminable|dummy)\b|
      \b[,;]?\s*(?i:importer)\b|
      \b[,;]?\s*(?i:frère|frere|père|pere|soeur|sister|bro)\.?(\b|\z)|
      (?i:no\s+data)|
      \b[,;]?\s*(?i:stet)[,!]?\s*\d*\z|
      [,;]?\s*\d+[-/\s+](?i:\d+|Jan|Feb|Mar|Apr|
        May|Jun|Jul|Aug|Sept?|
        Oct|Nov|Dec)\.?\s*[-/\s+]?\d+|
      \b[,;]?\s*(?i:Jan|Jan(uary|vier))[.,;]?\s*\d+|
      \b[,;]?\s*(?i:Feb|February|f(é|e)vrier)[.,;]?\s*\d+|
      \b[,;]?\s*(?i:Mar|Mar(ch|s))[.,;]?\s*\d+|
      \b[,;]?\s*(?i:Apr|Apri|April|avril)[.,;]?\s*\d+|
      \b[,;]?\s*(?i:Ma(y|i))[.,;]?\s*\d+|
      \b[,;]?\s*(?i:Jun|June|juin)[.,;]?\s*\d+|
      \b[,;]?\s*(?i:Jul|July|juillet)[.,;]?\s*\d+|
      \b[,;]?\s*(?i:Aug|August|ao(û|u)t)[.,;]?\s*\d+|
      \b[,;]?\s*(?i:Sep|Sept|Septemb(er|re))[.,;]?\s*\d+|
      \b[,;]?\s*(?i:Oct|Octob(er|re))[.,;]?\s*\d+|
      \b[,;]?\s*(?i:Nov|Novemb(er|re))[.,;]?\s*\d+|
      \b[,;]?\s*(?i:Dec|D(é|e)cemb(er|re))[.,;]?\s*\d+|
      \d+\s+(?i:Jan|Jan(uary|vier))\.?\b|
      \d+\s+(?i:Feb|February|f(é|e)vrier)\.?\b|
      \d+\s+(?i:Mar|March|mars)\.?\b|
      \d+\s+(?i:Apr|Apri|April|avril)\.?\b|
      \d+\s+(?i:Ma(y|i))\b|
      \d+\s+(?i:Jun|June|juin)\.?\b|
      \d+\s+(?i:Jul|July|juillet)\.?\b|
      \d+\s+(?i:Aug|August|ao(û|u)t)\.?\b|
      \d+\s+(?i:Sep|Septemb(er|re))t?\.?\b|
      \d+\s+(?i:Oct|Octob(er|re))\.?\b|
      \d+\s+(?i:Nov|Novemb(er|re))\.?\b|
      \d+\s+(?i:Dec|D(e|é)cemb(er|re))\.?\b|
      (?i:autres?\s+de|probably)|
      (?i:fide)\:?\s*\b|
      (?i:game\s+dept)\.?\s*\b|
      (?i:see\s+notes?\s*(inside)?)|
      (?i:see\s+letter\s+enclosed)|
      (?i:pers\.?\s+comm\.?)|
      (?i:crossed\s+out)|
      (?i:revised|photograph|fruits\s+only)|
      -?\s*(?i:sight\s+(id|identifi?cation))\.?\s*\b|
      (?i:doubtful)|
      -?\s*(?i:synonym(y|ie))|
      \b\s*\(?(?i:(fe)?male)\)?\s*\b|
      \b(?i:to\s+(sub)?spp?)\.?|
      (?i:nom\.?\s+rev\.?)|
      FNA|DAO|HUH|\(MT\)|(?i:\(KEW\))|
      (?i:uqam)|
      \b[,;]\s+\d+\z|
      [":!]|
      [,]?\d+|
      \s+\d+?(\/|\.)?(?i:i|ii|iii|iv|v|vi|vii|viii|ix|x)(\/|\.)\d+|
      [,;]\z|
      ^\w{0,2}\z|
      ^[A-Z]{2,}\z|
      \s+(?i:stet)\s*!?\s*\z|
      \s+(?i:prep)\.?\s*\z
    }x

    SPLIT_BY = %r{
      [–|&+/;]|
      \s+-\s+|
      \b(?i:and|et|with|per)\s+|
      \b(?i:annotated(\s+by)?)\s*\b|
      \b(?i:coll\.)\s*\b|
      \b(?i:conf\.?(\s+by)?|confirmed(\s+by)?)\s*\b|
      \b(?i:checked?(\s+by)?)\s*\b|
      \b(?i:det\.?(\s+by)?)\s*\b|
      \b(?i:dupl?\.?(\s+by)?|duplicate(\s+by)?)\s*\b|
      \b(?i:ex\.?(\s+by)?|examined(\s+by)?)\s*\b|
      \b(?i:in?dentified(\s+by)?)\s*\b|
      \b(?i:in\s+part(\s+by)?)\s*\b|
      \b(?i:or)\s+|
      \b(?i:prep\.?\s+(?i:by)?)\s*\b|
      \b(?i:redet\.?(\s+by?)?)\s*\b|
      \b(?i:reidentified(\s+by)?)\s*\b|
      \b(?i:stet)\s*\b|
      \b(?i:then(\s+by)?)\s+|
      \b(?i:veri?f?\.?\:?(\s+by)?|v(e|é)rifi(e|é)d?(\s+by)?)\s*\b|
      \b(?i:via|from)\s*\b|
      \b(?i:(donated)?\s*by)\s+
    }x

    CHAR_SUBS = {
      '(' => ' ',
      ')' => ' ',
      '[' => ' ',
      ']' => ' ',
      '?' => '',
      '!' => '',
      '=' => '',
      '#' => '',
      '/' => ' / ',
      '&' => ' & '
    }

    BLACKLIST = %r{
      (?i:abundant)|
      (?i:adult|juvenile)|
      (?i:believe|unclear|illegible)|
      (?i:biolog|botan|zoo|ecolog|mycol|(in)?vertebrate|fisheries|genetic|animal|mushroom|wildlife|plumage|flower|agriculture)|
      (?i:bris?tish|canadi?an?|chinese|arctic|japan|russian|north\s+america)|
      (?i:herbarium|herbier|collection|collected|publication|specimen|species|describe|an(a|o)morph|isolated|recorded|inspection|define|status)|
      \b\s*(?i:help)\s*\b|
      (?i:description|drawing|identification|remark|original|illustration|checklist|intermedia|measurement|indisting|series)|
      (?i:internation|gou?vern|ministry|unit|district|provincial|na(c|t)ional|military|region|environ|natur(e|al)|naturelles|division|program|direction)|
      (?i:o?\.?m\.?n\.?r\.?)|
      (?i:mus(eum|ée)|universit(y|é)|college|institute?|acad(e|é)m|school|écol(e|iers?)|polytech|dep(t|art?ment)|research|clinic|hospital|cientifica|sanctuary|safari)|
      (?i:graduate|student|supervisor|rcmp|coordinator|minority|police|taxonomist|consultant|team|équipe|memb(er|re)|crew|group|staff|personnel|family|captain|friends|assistant|worker)|
      (?i:non\s+pr(é|e)cis(é|e))|
      (?i:ontario|qu(e|é)bec|assurance)|
      (?i:soci(e|é)t(y|é)|cent(er|re)|community|history|conservation|conference|assoc|class|commission|consortium|council|club|alliance|protective|circle)|
      (?i:commercial|company|control|product)|
      (?i:survey|assessment|station|monitor|stn\.|index|project|bureau|engine|expedi(c|t)ion|festival|generation|inventory|marine)|
      (?i:workshop|garden|farm|jardin|public)
    }x

    TITLE = /\s*\b(sir|lord|count(ess)?|(gen|adm|col|maj|capt|cmdr|lt|sgt|cpl|pvt|prof|dr|md|ph\.?d|rev|docteur|mme|abbé|ptre)\.?|frère|frere|père|pere)(\s+|$)/i

    Namae.options[:prefer_comma_as_separator] = true
    Namae.options[:separator] = SPLIT_BY
    Namae.options[:title] = TITLE

    def self.parse(name)
      Namae.parse(name.gsub(STRIP_OUT, ' ')
                      .gsub(/[#{CHAR_SUBS.keys.join('\\')}]/, CHAR_SUBS)
                      .gsub(/([A-Z]{1}\.)([[:alpha:]]{2,})/, '\1 \2')
                      .gsub(/,\z/, '')
                      .squeeze(' ').strip)
    end

    def self.clean(parsed_namae)
      blank_name = { given: nil, family: nil }

      if parsed_namae.family && parsed_namae.family.length < 3
        return blank_name
      end
      if parsed_namae.family && parsed_namae.family.length == 3 && parsed_namae.family.count('.') == 1
        return blank_name
      end
      if parsed_namae.given && parsed_namae.given.count('.') >= 3 && /\.\s*[a-zA-Z]{4,}\s+[a-zA-Z]{1,}\./.match(parsed_namae.given)
        return blank_name
      end
      if parsed_namae.family && /[a-zA-Z]{2,}\.?\s+[a-zA-Z]{2,}/.match(parsed_namae.family)
        return blank_name
      end
      if parsed_namae.given && /[a-zA-Z]{2,}\.?\s+[a-zA-Z]{2,}/.match(parsed_namae.given)
        return blank_name
      end
      if parsed_namae.display_order =~ BLACKLIST
        return blank_name
      end

      if parsed_namae.given && 
          parsed_namae.family && 
          parsed_namae.family.count(".") > 0 && 
          parsed_namae.family.length - parsed_namae.family.count(".") <= 3
        given = parsed_namae.given
        family = parsed_namae.family
        parsed_namae.family = given
        parsed_namae.given = family
      end

      family = parsed_namae.family.gsub(/\.\z/, '').strip rescue nil
      given = parsed_namae.normalize_initials.given.strip rescue nil
      particle = parsed_namae.normalize_initials.particle.strip rescue nil

      if family.nil? && !given.nil? && !given.include?(".")
        family = given
        given = nil
      end

      if !family.nil? && given.nil? && !particle.nil?
        given = particle.sub(/^(.)/) { $1.capitalize }
        particle = nil
      end

      if !family.nil? && (family == family.upcase || family == family.downcase)
        family = family.mb_chars.capitalize.to_s rescue nil
      end

      if !given.nil? && (given == given.upcase || given == given.downcase) && !given.include?(".")
        given = given.mb_chars.capitalize.to_s rescue nil
      end

      { given: given, family: family }
    end

    def self.valid_year(year)
      return if year.presence.nil?

      parsed = Date.strptime(year, "%Y").year rescue nil

      if parsed.nil? || parsed <= 1756 || parsed >= Time.now.year
        parsed = Chronic.parse(year).year rescue nil
      end

      if !parsed.nil? && parsed >= 1756 && parsed <= Time.now.year
        parsed
      end
    end

    def self.valid_date(date)
      return if date.presence.nil?

      parsed = Date.strptime(date, "%Y-%m-%d") rescue nil

      if parsed.year.nil? || parsed.year <= 1756 || parsed.year >= Time.now.year
        parsed = Chronic.parse(date) rescue nil
      end

      if !parsed.year.nil? && parsed.year >= 1756 && parsed.year <= Time.now.year
        parsed
      end
    end

    def self.doi_clean(doi)
      sub = %r{
        ^http\:\/\/dx\.doi\.org\/|
        ^http\:\/\/doi\.org\/|
        ^(?i:doi)[\=\:]?\s*
      }x
      doi.gsub(sub,'')
    end

    def self.is_orcid?(orcid)
      matcher = %r{
        ^\d{4}-\d{4}-\d{4}-\d{3}[0-9X]$
      }x
      !!(matcher.match orcid)
    end

  end
end
# encoding: utf-8

module Collector
  module AgentUtility

    STRIP_OUT = %r{
      \b\d+\(?(?i:[[:alpha:]])\)?\b|
      \b(?i:et\s+al\.?)|
      \bu\.\s*a\.|
      \b,?\s*(?i:and|&)?\s*(?i:others)\s*\b|
      \b,?\s*(?i:etc(\.)?)|
      \b(?i:on)\b|
      \b(?i:unknown)\b|
      \b(?i:ann?onymous)\b|
      \b(?i:undetermined)\b|
      \b(?i:stet)[,!]?\s*\d*$|
      \d+/(?i:Jan|Feb|Mar|Apr|
        May|Jun|Jul|Aug|Sept?|
        Oct|Nov|Dec)\.?\s*/\d+|
      \b;?\s*(?i:Jan|Jan(uary|vier))[.,;]?\s*\d+|
      \b;?\s*(?i:Feb|February|f(é|e)vrier)[.,;]?\s*\d+|
      \b;?\s*(?i:Mar|Mar(ch|s))[.,;]?\s*\d+|
      \b;?\s*(?i:Apr|Apri|April|avril)[.,;]?\s*\d+|
      \b;?\s*(?i:Ma(y|i))[.,;]?\s*\d+|
      \b;?\s*(?i:Jun|June|juin)[.,;]?\s*\d+|
      \b;?\s*(?i:Jul|July|juillet)[.,;]?\s*\d+|
      \b;?\s*(?i:Aug|August|ao(û|u)t)[.,;]?\s*\d+|
      \b;?\s*(?i:Sep|Sept|Septemb(er|re))[.,;]?\s*\d+|
      \b;?\s*(?i:Oct|Octob(er|re))[.,;]?\s*\d+|
      \b;?\s*(?i:Nov|Novemb(er|re))[.,;]?\s*\d+|
      \b;?\s*(?i:Dec|D(é|e)cemb(er|re))[.,;]?\s*\d+|
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
      \b[,;]\s+\d+|
      [":\d+]|
      [,;]$|
      ^\w{0,2}$
    }x

    SPLIT_BY = %r{
      [–|&\/;]|
      \s+-\s+|
      \b(?i:with|and|et)\s+|
      \b(?i:annotated(\s+by)?)\s*\b|
      \b(?i:conf\.?(\s+by)?|confirmed(\s+by)?)\s*\b|
      \b(?i:checked?(\s+by)?)\s*\b|
      \b(?i:det\.?(\s+by)?)\s*\b|
      \b(?i:dupl?\.?(\s+by)?|duplicate(\s+by)?)\s*\b|
      \b(?i:ex\.?(\s+by)?|examined(\s+by)?)\s*\b|
      \b(?i:in?dentified(\s+by)?)\s*\b|
      \b(?i:in\s+part(\s+by)?)\s*\b|
      \b(?i:redet\.?(\s+by?)?)\s*\b|
      \b(?i:reidentified(\s+by)?)\s*\b|
      \b(?i:stet)!?\s\b*|
      \b(?i:then(\s+by)?)\s+|
      \b(?i:veri?f?\.?\:?(\s+by)?|verified?(\s+by)?)\s*\b|
      \b(?i:vérifié)\s*\b|
      \b(?i:by)\s+|
      \b(?i:or)\s+
    }x

    CHAR_SUBS = {
      '(' => ' ',
      ')' => ' ',
      '[' => ' ',
      ']' => ' ',
      '?' => '',
      '!' => '',
      '=' => ''
    }

    Namae.options[:prefer_comma_as_separator] = true
    Namae.options[:separator] = SPLIT_BY

    def self.clean(parsed_namae)

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

    def self.parse(name)
      cleaned = name.gsub(STRIP_OUT, ' ')
                    .gsub(/[#{CHAR_SUBS.keys.join('\\')}]/, CHAR_SUBS)
                    .gsub(/,\z/, '')
                    .squeeze(' ')

      Namae.parse(cleaned)
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

    def self.doi_clean(doi)
      sub = %r{
        ^http\:\/\/dx\.doi\.org\/|
        ^http\:\/\/doi\.org\/|
        ^(?i:doi)[\=\:]?\s*
      }x
      doi.gsub(sub,'')
    end

  end
end
# encoding: utf-8

module Collector
  module Utility

    def self.clean_namae(parsed_namae)
      family = parsed_namae[0].family rescue nil
      given = parsed_namae[0].normalize_initials.given rescue nil

      if family.nil? && !given.nil? && !given.include?(".")
        family = given
        given = nil
      end

      if !family.nil? && (family == family.upcase || family == family.downcase)
        family = family.mb_chars.capitalize.to_s rescue nil
      end

      if !given.nil? && (given == given.upcase || given == given.downcase) && !given.include?(".")
        given = given.mb_chars.capitalize.to_s rescue nil
      end

      OpenStruct.new(given: given, family: family)
    end

    def self.explode_names(name)
      global_strip_out = %r{
        \bet\s+al(\.)?|
        \bu\.\s*a\.|
        (\band|\&)\s+others|
        \betc(\.)?|
        \b,\s+\d+|
        \b(?i:on)\b|
        \b(?i:others)\b|
        \b(?i:unknown)\b|
        \b(?i:ann?onymous)\b|
        \b(?i:undetermined)\b|
        \b\d+/(Jan(\.)?|Feb(\.)?|Mar(\.)?|Apr(\.)?|May(\.)?|Jun(\.)?|Jul(\.)?|Aug(\.)?|Sep(\.)?|Oct(\.)?|Nov(\.)?|Dec(\.)?)/\d+|
        \bJan(\.)?(;)?(\s+)?\d+|\bJanuary(;)?(\s+)?\d+|
        \bFeb(\.)?(;)?(\s+)?\d+|\bFebruary(;)?(\s+)?\d+|
        \bMar(\.)?(;)?(\s+)?\d+|\bMarch(;)?(\s+)?\d+|
        \bApr(\.)?(;)?(\s+)?\d+|\bApril(;)?(\s+)?\d+|
        \bMay(;)?(\s+)?\d+|
        \bJun(\.)?(;)?(\s+)?\d+|\bJune(;)?(\s+)?\d+|
        \bJul(\.)?(;)?(\s+)?\d+|\bJuly(;)?(\s+)?\d+|
        \bAug(\.)?(;)?(\s+)?\d+|\bAugust(;)?(\s+)?\d+|
        \bSep(\.)?(;)?(\s+)?\d+|\bSeptember(;)?(\s+)?\d+|
        \bOct(\.)?(;)?(\s+)?\d+|\bOctober(;)?(\s+)?\d+|
        \bNov(\.)?(;)?(\s+)?\d+|\bNovember(;)?(\s+)?\d+|
        \bDec(\.)?(;)?(\s+)?\d+|\bDecember(;)?(\s+)?\d+|
        \d+\s+Jan(\.)?\b|\d+\s+January\b|
        \d+\s+Feb(\.)?\b|\d+\s+February\b|
        \d+\s+Mar(\.)?\b|\d+\s+March\b|
        \d+\s+Apr(\.)?\b|\d+\s+April\b|
        \d+\s+May\b|
        \d+\s+Jun(\.)?\b|\d+\s+June\b|
        \d+\s+Jul(\.)?\b|\d+\s+July\b|
        \d+\s+Aug(\.)?\b|\d+\s+August\b|
        \d+\s+Sep(\.)?\b|\d+\s+September\b|
        \d+\s+Oct(\.)?\b|\d+\s+October\b|
        \d+\s+Nov(\.)?\b|\d+\s+November\b|
        \d+\s+Dec(\.)?\b|\d+\s+December\b|
        [":\d+]
      }x

      character_substitutions = {
        '.' => '. ',
        '(' => ' ',
        ')' => ' ',
        '[' => ' ',
        ']' => ' ',
        '?' => '',
        '!' => '',
        '=' => ''
      }

      split_by = %r{
        [–|&\/;]|
        \b(?:\s+-\s+)\b|
        \b(?i:with|and|et)\b|
        \b(?i:annotated(\s+by)?\s+)\b|
        \b(?i:conf\.?(\s+by)?\s+|confirmed(\s+by)?\s+)\b|
        \b(?i:checked(\s+by)?\s+)\b|
        \b(?i:det\.?(\s+by)?\s+)\b|
        \b(?i:dupl?\.?(\s+by)?\s+|duplicate(\s+by)?\s+)\b|
        \b(?i:ex\.?(\s+by)?\s+|examined(\s+by)?\s+)\b|
        \b(?i:in?dentified(\s+by)?\s+)\b|
        \b(?i:in\s+part(\s+by)?\s+)\b|
        \b(?i:redet\.?(\s+by?)?\s+)\b|
        \b(?i:reidentified(\s+by)?\s+)\b|
        \b(?i:stet!?)\b|
        \b(?i:then(\s+by)?\s+)\b|
        \b(?i:ver\.?(\s+by)?\s+|verf\.?(\s+by)?\s+|verified?(\s+by)?\s+)\b
      }x

      name.gsub(global_strip_out, '')
          .gsub(/[#{character_substitutions.keys.join('\\')}]/, character_substitutions)
          .squeeze(' ')
          .split(split_by)
          .map{ |c| c.strip.gsub(/[.,]\z/, '').strip }
          .reject{ |c| c.empty? || c.length < 3 || c.length > 30 }
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

  end
end
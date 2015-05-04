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
      strip_out = %r{
        \bet\s+al(\.)?|
        \bu\.\s*a\.|
        (\band|\&)\s+others|
        \betc(\.)?|
        \b,\s+\d+|
        \b(?i:unknown)\b|
        \b(?i:ann?onymous)\b|
        \b(?i:undetermined)\b|
        [":\d+]
      }x

      substitutions = {
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

      name.gsub(strip_out, '')
          .gsub(/[#{substitutions.keys.join('\\')}]/, substitutions).squeeze(' ')
          .split(split_by)
          .map{ |c| c.strip }
          .reject{ |c| c.empty? || c.length < 3 || c.length > 30 }
    end

    def self.valid_year(year)
      return if year.presence.nil?

      begin
        parsed = Date.strptime(year, "%Y").year
      rescue
        parsed = Chronic.parse(year).year rescue nil
      end

      if !parsed.nil? && parsed >= 1756 && parsed <= Time.now.year
        parsed.to_s
      end
    end

  end
end
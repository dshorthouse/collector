module Collector
  class Utility

    def self.clean_namae(parsed_namae)
      family = parsed_namae[0].family rescue nil
      given = parsed_namae[0].normalize_initials.given rescue nil

      if family.nil? && !given.nil? && !given.include?(".")
        family = given
        given = nil
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
        [\[\]":\d+]
      }x

      split_by = %r{
        [–;|&/!?]|
        \b(?:\s+-\s+)\b|
        \b(?i:with|and|et)\b|
        \b(?i:annotated(\s+by)?\s+)\b|
        \b(?i:conf\.?(\s+by)?\s+|confirmed(\s+by)?\s+)\b|
        \b(?i:checked(\s+by)?\s+)\b|
        \b(?i:dupl?\.?(\s+by)?\s+|duplicate(\s+by)?\s+)\b|
        \b(?i:ex\.?(\s+by)?\s+|examined(\s+by)?\s+)\b|
        \b(?i:in\s+part(\s+by)?\s+)\b|
        \b(?i:stet!?)\b|
        \b(?i:ver\.?(\s+by)?\s+|verified(\s+by)?\s+)\b
      }x

      name.gsub(strip_out, '')
          .gsub(/\./,'. ').squeeze(' ')
          .split(split_by)
          .map{ |c| c.strip.mb_chars.titleize.to_s }
          .reject{ |c| c.empty? || c.length < 3 }
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
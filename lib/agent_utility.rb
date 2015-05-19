# encoding: utf-8

module Collector
  module AgentUtility

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
        \b(?i:on)\b|
        \b(?i:others)\b|
        \b(?i:unknown)\b|
        \b(?i:ann?onymous)\b|
        \b(?i:undetermined)\b|
        \d+/(?i:
          Jan(\.)?(\s+)?|
          Feb(\.)?(\s+)?|
          Mar(\.)?(\s+)?|
          Apr(\.)?(\s+)?|
          May(\.)?(\s+)?|
          Jun(\.)?(\s+)?|
          Jul(\.)?(\s+)?|
          Aug(\.)?(\s+)?|
          Sep(t)?(\.)?(\s+)?|
          Oct(\.)?(\s+)?|
          Nov(\.)?(\s+)?|
          Dec(\.)?(\s+)?
          )/\d+|
        \b(?i:Jan|Jan(uary|vier))(\.)?(;)?(\s+)?\d+|
        \b(?i:Feb|February|f(é|e)vrier)(\.)?(;)?(\s+)?\d+|
        \b(?i:Mar|Mar(ch|s))(\.)?(;)?(\s+)?\d+|
        \b(?i:Apr|Apri|April|avril)(\.)?(;)?(\s+)?\d+|
        \b(?i:Ma(y|i))(;)?(\s+)?\d+|
        \b(?i:Jun|June|juin)(\.)?(;)?(\s+)?\d+|
        \b(?i:Jul|July|juillet)(\.)?(;)?(\s+)?\d+|
        \b(?i:Aug|August|ao(û|u)t)(\.)?(;)?(\s+)?\d+|
        \b(?i:Sep|Sept|Septemb(er|re))(\.)?(;)?(\s+)?\d+|
        \b(?i:Oct|Octob(er|re))(\.)?(;)?(\s+)?\d+|
        \b(?i:Nov|Novemb(er|re))(\.)?(;)?(\s+)?\d+|
        \b(?i:Dec|D(é|e)cemb(er|re))(\.)?(;)?(\s+)?\d+|
        \d+\s+(?i:Jan|Jan(uary|vier))(\.)?\b|
        \d+\s+(?i:Feb|February|f(é|e)vrier)(\.)?\b|
        \d+\s+(?i:Mar|March|mars)(\.)?\b|
        \d+\s+(?i:Apr|Apri|April|avril)(\.)?\b|
        \d+\s+(?i:Ma(y|i))\b|
        \d+\s+(?i:Jun|June|juin)(\.)?\b|
        \d+\s+(?i:Jul|July|juillet)(\.)?\b|
        \d+\s+(?i:Aug|August|ao(û|u)t)(\.)?\b|
        \d+\s+(?i:Sep|Septemb(er|re))(t)?(\.)?\b|
        \d+\s+(?i:Oct|Octob(er|re))(\.)?\b|
        \d+\s+(?i:Nov|Novemb(er|re))(\.)?\b|
        \d+\s+(?i:Dec|D(e|é)cemb(er|re))(\.)?\b|
        \b,\s+\d+|
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
        \b(?i:verf?\.?(\s+by)?\s+|verified?(\s+by)?\s+)\b
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
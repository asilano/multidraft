module UniqueSuggestion
  extend ActiveSupport::Concern

  module ClassMethods
    def suggest(field, base_value, options = {})
      # Set defaults
      pattern = options[:pattern] || '{base} ({num})'
      strategy = options[:strategy] || :first_available

      raise ArgumentError.new("options[:strategy] is invalid") unless [:first_available, :next_highest].include? strategy
      raise ArgumentError.new("options[:pattern] is invalid") unless (/\{base\}/ =~ pattern && /\{num\}/ =~ pattern)

      # Process the supplied pattern into one usable by SQL LIKE
      # and one which will function as a Regexp
      pattern.gsub!(/\{base\}/, base_value)
      like_pattern = pattern.gsub(/\{num\}/, '%')
      regex_pattern = Regexp.new(Regexp.escape(pattern).gsub('\{num\}', '(\d+)'),
                                  Regexp::IGNORECASE)

      # Ask the database which values have already been taken
      base_exists = exists?(field => base_value)
      numbers_taken = where { __send__(field) =~ like_pattern }
                        .pluck(field)
                        .map { |val| regex_pattern.match(val).andand[1].to_i }.compact

      case strategy
      when :first_available
        # Return the first possible name that hasn't been used
        return base_value unless base_exists

        # Assume 1 is taken (so the minimal pair is Base and Base (2))
        num = (2..Float::INFINITY).detect { |n| !numbers_taken.include? n }
        return pattern.gsub(/\{num\}/, "#{num}")
      when :next_highest
        # Return the first possible name that's beyond all those currently in use
        return base_value if (!base_exists && numbers_taken.empty?)

        # Assume 1 is taken (so the minimal pair is Base and Base (2))
        return pattern.gsub(/\{num\}/, "#{(numbers_taken.max || 1) + 1}")
      end
    end
  end
end

ActiveRecord::Base.send(:include, UniqueSuggestion)
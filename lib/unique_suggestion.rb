module UniqueSuggestion
  extend ActiveSupport::Concern

  module ClassMethods
    def suggest(field, base_value, options = {})
      # Set defaults
      pattern = options[:pattern] || '{base} ({num})'
      strategy = options[:strategy] || :first_available

      raise ArgumentError.new("options[:strategy] is invalid") unless [:first_available, :next_highest].include? strategy

      # Process the supplied pattern into one usable by SQL LIKE
      # and one which will function as a Regexp
      like_pattern = pattern.gsub(/\{base\}/, base_value)
                            .gsub(/\{num\}/, '%')
      regex_pattern = Regexp.new(Regexp.escape(pattern.gsub('{base}', base_value))
                                      .gsub('\{num\}', '(\d+)'))

      # Ask the database which values have already been taken
      base_exists = exists?(field => base_value)
      numbers_taken = where("#{field} LIKE ?", like_pattern)
                        .pluck(field)
                        .map { |val| regex_pattern.match(val)[1].to_i }

      case strategy
      when :first_available
        # Return the first possible name that hasn't been used
        return base_value unless base_exists

        num = (1..Float::INFINITY).detect { |n| !numbers_taken.include? n }
        return pattern.gsub(/\{base\}/, base_value).gsub(/\{num\}/, "#{num}")
      when :next_highest
        # Return the first possible name that's beyond all those currently in use
        return base_value if (!base_exists && numbers_taken.empty?)

        return pattern.gsub(/\{base\}/, base_value).gsub(/\{num\}/, "#{numbers_taken.max + 1}")
      end
    end
  end
end

ActiveRecord::Base.send(:include, UniqueSuggestion)
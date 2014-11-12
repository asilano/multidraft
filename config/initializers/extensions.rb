require 'unique_suggestion'

class Array
  def recursive_map(&block)
    map do |val|
      if val.kind_of? Array
        val.recursive_map &block
      else
        block.call val
      end
    end
  end

  def replace_elems(value)
    ElementReplacer.new(self, value)
  end

private
  class ElementReplacer
    def initialize(arr, value)
      @arr = arr
      @old_value = value
    end

    def with(new_value)
      @arr.map! do |cur_val|
        @old_value === cur_val ? new_value : cur_val
      end
    end
  end
end
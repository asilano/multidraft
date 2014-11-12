module FixAll
  def all(expected)
    RSpec::Matchers::BuiltIn::All.new(expected)
  end
end
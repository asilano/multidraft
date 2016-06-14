class CardInstance < ActiveRecord::Base
  belongs_to :card_template, touch: true

  # Delegate attribute fields in the proper way...
  delegate :name, :slot, :fields, to: :card_template, allow_nil: true

  # ... and delegate "everything else" via method_missing, taking care that a nil
  # card template isn't a problem
  def method_missing(name, *args, &block)
    respond_to_missing?(name) ? card_template.andand.send(name, *args, &block) : super
  end

  def respond_to_missing?(name, include_priv = false)
    (CardTemplate.method_defined?(name) && card_template.respond_to?(name)) || super
  end
end

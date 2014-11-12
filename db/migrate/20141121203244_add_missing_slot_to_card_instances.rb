class AddMissingSlotToCardInstances < ActiveRecord::Migration
  def change
    add_column :card_instances, :missing_slot, :string
  end
end

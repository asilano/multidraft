class RenameRarityToSlotOnCardTemplates < ActiveRecord::Migration
  def change
    rename_column :card_templates, :rarity, :slot
  end
end

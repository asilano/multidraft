class CreateCardTemplates < ActiveRecord::Migration
  def change
    create_table :card_templates do |t|
      t.references :card_set
      t.string :name, :null => false
      t.string :rarity, :null => false
      t.text :fields

      t.timestamps
    end
  end
end

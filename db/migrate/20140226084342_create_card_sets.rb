class CreateCardSets < ActiveRecord::Migration
  def change
    create_table :card_sets do |t|
      t.string :name, null: false
      t.time :last_modified, null: false, default: Time.at(0)
      t.boolean :remote_dictionary
      t.string :dictionary_location, null: false

      t.timestamps
    end

    add_index :card_sets, [:name, :last_modified], unique: true
  end
end

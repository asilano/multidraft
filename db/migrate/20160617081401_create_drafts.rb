class CreateDrafts < ActiveRecord::Migration
  def change
    create_table :drafts do |t|
      t.string :name, null: false
      t.integer :state

      t.timestamps
    end
  end
end

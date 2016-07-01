class CreateDrafters < ActiveRecord::Migration
  def change
    create_table :drafters do |t|
      t.references :user, index: true
      t.references :draft, index: true

      t.timestamps
    end
  end
end

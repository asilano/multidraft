class CreateCardInstances < ActiveRecord::Migration
  def change
    create_table :card_instances do |t|
      t.belongs_to :card_template

      t.timestamps
    end
  end
end

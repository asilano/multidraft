class AddBoosterDistrToCardSets < ActiveRecord::Migration
  def change
    add_column :card_sets, :booster_distr, :text
  end
end

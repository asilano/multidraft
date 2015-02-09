class AddLayoutToCardTemplates < ActiveRecord::Migration
  class CardTemplate < ActiveRecord::Base
    serialize :fields
  end

  def up
    add_column :card_templates, :layout, :string, default: 'normal'

    CardTemplate.all.each do |card|
      card.layout = card.fields.delete('layout') || 'normal'
      card.save!
    end
  end

  def down
    CardTemplate.all.each do |card|
      card.fields['layout'] = card.layout
      card.save!
    end

    remove_column :card_templates, :layout
  end
end

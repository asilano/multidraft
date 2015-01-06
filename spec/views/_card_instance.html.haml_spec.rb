require 'spec_helper'

describe 'card_instance partial' do
  it 'should just display the missing slot if present' do
    card = double(:card, missing_slot: 'Rare')
    render 'shared/card_instance', card: card

    expect(rendered).to have_css('.card', text: 'Rare')
  end

  it "should pass several other tests"
end
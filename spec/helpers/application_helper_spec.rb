require 'spec_helper'

describe ApplicationHelper do
  describe '#image_for_card' do
    before(:each) { @shock = FactoryGirl.create(:card_instance) }

    it 'should give the correct Gatherer URL when card has a multiverseid' do
      html = image_for_card @shock
      expect(html).to have_css('img')

      image = node(html).first('img')
      expect(image['src']).to eq 'http://gatherer.wizards.com/Handlers/Image.ashx?type=card&multiverseid=123456'
    end

    it 'should give the correct URL when card has an imageURL' do
      @shock.card_template.fields['imageURL'] = 'http://example.com/shock.jpg'
      html = image_for_card @shock
      expect(html).to have_css('img')

      image = node(html).first('img')
      expect(image['src']).to eq 'http://example.com/shock.jpg'
    end

    it 'should give nil if card has no template' do
      @shock.card_template = nil
      @shock.save!

      expect(image_for_card @shock).to be_nil
    end

    it 'should give nil if card has no images' do
      @shock.card_template.fields['multiverseid'] = nil
      @shock.card_template.fields['imageURL'] = nil
      @shock.save!

      expect(image_for_card @shock).to be_nil
    end

    it 'should pick a random image for a normal card with several' do
      @shock.card_template.fields['multiverseid'] = [123, 456, 789]
      @shock.card_template.save!

      images = 1.upto(999).map { image_for_card @shock }
      srcs = images.map { |html| node(html).first('img')['src'] }

      expect(srcs).to all( be_in(['http://gatherer.wizards.com/Handlers/Image.ashx?type=card&multiverseid=123',
                                  'http://gatherer.wizards.com/Handlers/Image.ashx?type=card&multiverseid=456',
                                  'http://gatherer.wizards.com/Handlers/Image.ashx?type=card&multiverseid=789']))
      expect(srcs).to satisfy{ |ss| !ss.all? { |s| s == 'http://gatherer.wizards.com/Handlers/Image.ashx?type=card&multiverseid=123' } }
      expect(srcs).to satisfy{ |ss| !ss.all? { |s| s == 'http://gatherer.wizards.com/Handlers/Image.ashx?type=card&multiverseid=456' } }
      expect(srcs).to satisfy{ |ss| !ss.all? { |s| s == 'http://gatherer.wizards.com/Handlers/Image.ashx?type=card&multiverseid=789' } }
    end

    it 'should pick a random image for a normal card with several URLs' do
      @shock.card_template.fields['imageURL'] = ['shock', 'shock2', 'shock3'].map { |n| "http://example.com/#{n}.jpg"}
      @shock.card_template.save!

      images = 1.upto(999).map { image_for_card @shock }
      srcs = images.map { |html| node(html).first('img')['src'] }

      expect(srcs).to all( be_in(['http://example.com/shock.jpg',
                                    'http://example.com/shock2.jpg',
                                    'http://example.com/shock3.jpg']))
      expect(srcs).to satisfy{ |ss| !ss.all? { |s| s == 'http://example.com/shock.jpg' } }
      expect(srcs).to satisfy{ |ss| !ss.all? { |s| s == 'http://example.com/shock2.jpg' } }
      expect(srcs).to satisfy{ |ss| !ss.all? { |s| s == 'http://example.com/shock3.jpg' } }
    end

    it 'should pick the first image for a non-normal card with several' do
      @shock.card_template.fields['multiverseid'] = [123, 456, 789]
      @shock.card_template.layout = 'funky'
      @shock.card_template.save!

      images = 1.upto(999).map { image_for_card @shock }
      srcs = images.map { |html| node(html).first('img')['src'] }

      expect(srcs).to all( eq 'http://gatherer.wizards.com/Handlers/Image.ashx?type=card&multiverseid=123' )
    end

    it 'should create a flipping image for a DFC' do
      @shock.card_template.fields['multiverseid'] = [123456, 789101]
      @shock.card_template.layout = 'double-faced'
      @shock.card_template.save!

      html = image_for_card @shock
      parsed = node(html)

      # Check that the parsed HTML has exactly one div.dfc-container. We can do this by
      # checking there's exactly one direct child of the fake "body" tag Capybara created,
      # then checking that it has the properties expected
      expect(parsed).to have_css('body > *', count: 1)
      div = parsed.first('body > div.dfc-container')
      expect(div).not_to be_nil
      expect(div['title']).to eq @shock.name

      # Check that the top-level div has the expected children - an invisible image,
      # and a div containing the two face images
      expect(div).to have_css('> *', count: 2)
      expect(div).to have_css('> img.invisible-sizer')
      flipper = div.first('div.dfc-flipper')
      expect(flipper).not_to be_nil
      expect(flipper).to have_css("> img[alt='#{@shock.name}']", count: 2)
      expect(flipper.first('img.dfc-front')['src']).to match /multiverseid=123456$/
      expect(flipper.first('img.dfc-back')['src']).to match /multiverseid=789101$/
    end
  end
end
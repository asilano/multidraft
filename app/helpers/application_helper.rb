module ApplicationHelper
  def image_for_card(card)
    return nil unless card.card_template
    set_name = card.card_template.card_set.name
    image_urls = image_urls_for_card(card, set_name)

    unless image_urls.blank?
      # Special case for double-faced cards
      if card.layout.downcase == 'double-faced'
        return flip_images(image_urls, card.name)
      end

      image_tag image_url_by_layout(image_urls, card.layout), alt: card.name, title: card.name
    end
  end

  def image_urls_for_card(card, set_name)
    if card.fields['imageURL']
      [*card.fields['imageURL']].reject(&:blank?)
    elsif card.fields['imageName']
      [*card.fields['imageName']].reject(&:blank?).map {|name| url_from_image_name(name, set_name)}
    end
  end

  def image_url_by_layout(image_urls, layout)
    if layout && layout.downcase != 'normal'
      # Card has several images because of its unusual layout.
      # Render just the first one
      image_urls[0]
    else
      # Card has a normal layout, so its images are alternate possibilities
      # Pick one at random
      image_urls.sample
    end
  end

  # Write HTML for tthe front image, which flips to the back image on hover
  # This consists of an outer div, which detects the hover and provides context;
  # an inner div which actually rotates; and two images for the front and back faces.
  def flip_images(image_urls, title_text)
    content_tag :div, class: 'dfc-container', title: title_text do
      # Because all the children are absolutely positioned, the outer div has
      # no size, making it hard to hover on! Give it a second normal, inline
      # copy of the front face image (which we will hide) to force its size.
      html = image_tag(image_urls[0], class: 'invisible-sizer')
      html += content_tag :div, class: 'dfc-flipper' do
        image_tag(image_urls[0], alt: title_text, class: 'dfc-front') +
        image_tag(image_urls[1], alt: title_text, class: 'dfc-back')
      end
      html
    end
  end

  def url_from_image_name(image_name, set_name)
    "http://mtgimage.com/setname/#{set_name}/#{image_name}.jpg"
  end
end

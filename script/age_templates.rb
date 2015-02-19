# From CardSets, find those such that all their card_templates have no card_instances
# and haven't been updated for 24 hours (noting that changes to instances, including
# deletion, will touch the template.)
candidates = CardSet.with_no_card_instances.select { |cs| cs.card_templates.day_old.count == cs.card_templates.count }

# We know that the card_templates have no children, so we can just delete them without
# invoking callbacks.
candidates.each { |cs| cs.card_templates.delete_all }
require 'rails_helper'

feature "/drafts" do
  context 'when not logged in' do
    context 'there are no drafts' do
      scenario 'index still renders' do
        visit '/drafts'

        expect(page).to have_content("There aren't any drafts at the moment.")
        expect(page).to have_link("Create one!", href: new_draft_path)
        expect(page).to_not have_link("New draft", href: new_draft_path)
      end

      scenario 'create link redirects to login' do
        visit '/drafts'
        click_link 'Create one!'

        expect(current_path).to eq new_user_session_path
        expect(page).to have_content('You need to sign in or sign up before continuing.')
      end
    end

    context 'there are drafts' do
      let!(:drafts) { Array.new(5) { |i| FactoryGirl.create(:draft) } }

      scenario 'index renders' do
        visit '/drafts'

        expect(page).to have_content("Drafts waiting to start: #{drafts.length}")
        drafts.each do |draft|
          expect(page).to have_css('.draft--waiting .draft-id', text: draft.id)
          expect(page).to have_css('.draft--waiting .draft-name', text: draft.name)
        end

        expect(page).to_not have_link("Create one!", href: new_draft_path)
        expect(page).to have_link("New draft", href: new_draft_path)
      end

      scenario 'new link redirects to login' do
        visit '/drafts'
        click_link 'New draft'

        expect(current_path).to eq new_user_session_path
        expect(page).to have_content('You need to sign in or sign up before continuing.')
      end

      scenario 'clicking a draft redirects to login' do
        visit '/drafts'
        click_link drafts[0].name

        expect(current_path).to eq new_user_session_path
        expect(page).to have_content('You need to sign in or sign up before continuing.')
      end

      context '...in various states' do
        before(:each) do
          drafts[0].state = Draft::States::DRAFTING
          drafts[1].state = Draft::States::DECK_BUILDING
          drafts[2].state = Draft::States::ENDED
          drafts.each(&:save)
        end

        scenario 'index renders' do
          visit '/drafts'

          expect(page).to have_content("Drafts waiting to start: 2")
          drafts[3..4].each do |draft|
            expect(page).to have_css('.draft--waiting .draft-id', text: draft.id)
            expect(page).to have_css('.draft--waiting .draft-name', text: draft.name)
          end

          expect(page).to have_content("Drafts in progress: 2")
          drafts[0..1].each do |draft|
            expect(page).to have_css('.draft--running .draft-id', text: draft.id)
            expect(page).to have_css('.draft--running .draft-name', text: draft.name)
            expect(page).to have_css('.draft--running .draft-state', text: I18n.t("drafts.draft_list.states.#{draft.state}"))
          end

          expect(page).to have_content("Drafts completed: 1")
          drafts[2..2].each do |draft|
            expect(page).to have_css('.draft--ended .draft-id', text: draft.id)
            expect(page).to have_css('.draft--ended .draft-name', text: draft.name)
          end

          expect(page).to_not have_link("Create one!", href: new_draft_path)
          expect(page).to have_link("New draft", href: new_draft_path)
        end
      end
    end
  end

  context 'when logged in' do
    let(:user) { FactoryGirl.create(:confirmed_user) }
    before(:each) { login user }
    context 'there are no drafts' do
      scenario 'index still renders' do
        visit '/drafts'

        expect(page).to have_content("There aren't any drafts at the moment.")
        expect(page).to have_link("Create one!", href: new_draft_path)
        expect(page).to_not have_link("New draft", href: new_draft_path)
      end

      scenario 'create link renders New page' do
        visit '/drafts'
        click_link 'Create one!'

        expect(current_path).to eq new_draft_path
        expect(page).to have_content('Create a new draft')
      end
    end

    context 'there are drafts, none with user in' do
      let!(:drafts) { Array.new(5) { |i| FactoryGirl.create(:draft) } }
      before(:each) do
        drafts[0].state = Draft::States::DRAFTING
        drafts[1].state = Draft::States::DECK_BUILDING
        drafts[2].state = Draft::States::ENDED
        drafts.each(&:save)
      end

      scenario 'index renders' do
        visit '/drafts'

        within('.user-drafts') { expect(page).to have_content("You aren't in any drafts at the moment") }

        within('.nonuser-drafts') do
          expect(page).to have_content("Drafts waiting to start: 2")
          drafts[3..4].each do |draft|
            expect(page).to have_css('.draft--waiting .draft-id', text: draft.id)
            expect(page).to have_css('.draft--waiting .draft-name', text: draft.name)
          end

          expect(page).to have_content("Drafts in progress: 2")
          drafts[0..1].each do |draft|
            expect(page).to have_css('.draft--running .draft-id', text: draft.id)
            expect(page).to have_css('.draft--running .draft-name', text: draft.name)
            expect(page).to have_css('.draft--running .draft-state', text: I18n.t("drafts.draft_list.states.#{draft.state}"))
          end

          expect(page).to have_content("Drafts completed: 1")
          drafts[2..2].each do |draft|
            expect(page).to have_css('.draft--ended .draft-id', text: draft.id)
            expect(page).to have_css('.draft--ended .draft-name', text: draft.name)
          end
        end

        expect(page).to_not have_link("Create one!", href: new_draft_path)
        expect(page).to have_link("New draft", href: new_draft_path)
      end

      scenario 'clicking a draft shows that draft' do
        visit '/drafts'
        click_link drafts[1].name

        expect(current_path).to eq draft_path(drafts[1])
        expect(page).to have_content(drafts[1].name)
      end
    end

    context 'there are drafts, half with user in' do
      let!(:drafts) { Array.new(10) { |i| FactoryGirl.create(:draft) } }
      before(:each) { drafts[5..-1].each { |d| FactoryGirl.create(:drafter, user: user, draft: d) } }

      scenario 'index renders' do
        visit '/drafts'

        within('.user-drafts') do
          expect(page).to have_content("Drafts waiting to start: #{user.drafts.length}")
          user.drafts.each do |draft|
            expect(page).to have_css('.draft--waiting .draft-id', text: draft.id)
            expect(page).to have_css('.draft--waiting .draft-name', text: draft.name)
          end
        end

        within('.nonuser-drafts') do
          nonuser_drafts = Draft.all - user.drafts
          expect(page).to have_content("Drafts waiting to start: #{nonuser_drafts.length}")
          nonuser_drafts.each do |draft|
            expect(page).to have_css('.draft--waiting .draft-id', text: draft.id)
            expect(page).to have_css('.draft--waiting .draft-name', text: draft.name)
          end
        end

        expect(page).to_not have_link("Create one!", href: new_draft_path)
        expect(page).to have_link("New draft", href: new_draft_path)
      end

      context '...in various states' do
        before(:each) do
          drafts[0].state = Draft::States::DRAFTING
          drafts[1].state = Draft::States::DECK_BUILDING
          drafts[2].state = Draft::States::ENDED
          drafts[5].state = Draft::States::DRAFTING
          drafts[6].state = Draft::States::DECK_BUILDING
          drafts[7].state = Draft::States::ENDED
          drafts.each(&:save)
        end

        scenario 'index renders' do
          visit '/drafts'

          within('.user-drafts') do
            expect(page).to have_content("Drafts waiting to start: 2")
            drafts[8..9].each do |draft|
              expect(page).to have_css('.draft--waiting .draft-id', text: draft.id)
              expect(page).to have_css('.draft--waiting .draft-name', text: draft.name)
            end

            expect(page).to have_content("Drafts in progress: 2")
            drafts[5..6].each do |draft|
              expect(page).to have_css('.draft--running .draft-id', text: draft.id)
              expect(page).to have_css('.draft--running .draft-name', text: draft.name)
              expect(page).to have_css('.draft--running .draft-state', text: I18n.t("drafts.draft_list.states.#{draft.state}"))
            end

            expect(page).to have_content("Drafts completed: 1")
            drafts[7..6].each do |draft|
              expect(page).to have_css('.draft--ended .draft-id', text: draft.id)
              expect(page).to have_css('.draft--ended .draft-name', text: draft.name)
            end
          end

          within('.nonuser-drafts') do
            expect(page).to have_content("Drafts waiting to start: 2")
            drafts[3..4].each do |draft|
              expect(page).to have_css('.draft--waiting .draft-id', text: draft.id)
              expect(page).to have_css('.draft--waiting .draft-name', text: draft.name)
            end

            expect(page).to have_content("Drafts in progress: 2")
            drafts[0..1].each do |draft|
              expect(page).to have_css('.draft--running .draft-id', text: draft.id)
              expect(page).to have_css('.draft--running .draft-name', text: draft.name)
              expect(page).to have_css('.draft--running .draft-state', text: I18n.t("drafts.draft_list.states.#{draft.state}"))
            end

            expect(page).to have_content("Drafts completed: 1")
            drafts[2..2].each do |draft|
              expect(page).to have_css('.draft--ended .draft-id', text: draft.id)
              expect(page).to have_css('.draft--ended .draft-name', text: draft.name)
            end
          end

          expect(page).to_not have_link("Create one!", href: new_draft_path)
          expect(page).to have_link("New draft", href: new_draft_path)
        end

        scenario 'clicking a draft user is not in shows that draft' do
          visit '/drafts'
          click_link drafts[1].name

          expect(current_path).to eq draft_path(drafts[1])
          expect(page).to have_content(drafts[1].name)
        end

        scenario 'clicking a draft user is in shows that draft' do
          visit '/drafts'
          click_link drafts[8].name

          expect(current_path).to eq draft_path(drafts[8])
          expect(page).to have_content(drafts[8].name)
        end
      end
    end

    context 'there are many waiting drafts with different drafters' do
      let!(:drafts) { Array.new(9) { |i| FactoryGirl.create(:draft) } }
      before(:each) do
        drafts.each.with_index do |d, ix|
          ix.times { FactoryGirl.create(:drafter, draft: d) }
        end
      end

      scenario 'each draft mentions how many drafters it has' do
        visit '/drafts'

        drafts.each.with_index do |d, ix|
          within('.table-row.draft--waiting', text: d.name) do
            expect(page).to have_css('.draft-drafters', text: "#{d.drafters.count} #{'drafter'.pluralize d.drafters.count}")
          end
        end
      end
    end
  end
end
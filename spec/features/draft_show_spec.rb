require 'rails_helper'

feature "/drafts/:id" do
  let!(:draft) { FactoryGirl.create(:draft) }
  context 'when not logged in' do
    scenario 'redirects to login' do
      visit "/drafts/#{draft.id}"

      expect(current_path).to eq new_user_session_path
      expect(page).to have_content('You need to sign in or sign up before continuing.')
    end
  end

  context 'when logged in' do
    let(:user) { FactoryGirl.create(:confirmed_user) }
    before(:each) { login user }

    scenario 'visiting a non-existent draft redirects with flash' do
      visit "/drafts/#{Draft.pluck(:id).max + 1}"

      expect(current_path).to eq drafts_path
      expect(page).to have_css('#flash .notice', text: "Sorry, that draft doesn't seem to exist")
    end

    scenario 'visiting an Drafter-less Draft says so' do
      visit "/drafts/#{draft.to_param}"

      expect(current_path).to eq draft_path(draft)
      expect(page).to have_css('.draft-name', text: draft.name)
      within('.central-notice') do
        expect(page).to have_css('.notice-text', text: 'There are no drafters in this draft.')
        expect(page).to have_css('.sub-notice-text', text: 'Not even the creator...')
        expect(page).to have_button('Join this draft!')
      end
    end

    scenario 'clicking the Join button joins the draft' do
      visit "/drafts/#{draft.to_param}"
      click_button 'Join this draft!'

      expect(page).to have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
    end

    context 'when draft has drafters' do
      before(:each) do
        5.times { FactoryGirl.create(:drafter, draft: draft) }
      end

      scenario 'visiting a Draft lists the drafters' do
        visit "/drafts/#{draft.to_param}"

        expect(current_path).to eq draft_path(draft)
        expect(page).to have_css('.draft-name', text: draft.name)
        within('table.drafters-list') do
          expect(page).to have_css('thead tr th', text: 'Drafters')
          draft.drafters.each do |drafter|
            expect(page).to have_css('tr.row--drafter td.cell--drafter-name', text: drafter.user.name)
          end
        end
      end

      scenario 'clicking the Join button joins the draft' do
        visit "/drafts/#{draft.to_param}"
        expect(page).to_not have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)

        click_button 'Join this draft!'
        expect(page).to have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
      end

      scenario "doesn't display the Join button if user is already in" do
        Drafter.create(draft: draft, user: user)

        visit "/drafts/#{draft.to_param}"
        expect(page).to have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
        expect(page).to_not have_button('Join this draft!')
      end

      scenario "doesn't display the Join button for non-waiting drafts" do
        draft.update(state: Draft::States::DRAFTING)

        visit "/drafts/#{draft.to_param}"
        expect(page).to_not have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
        expect(page).to_not have_button('Join this draft!')

        draft.update(state: Draft::States::DECK_BUILDING)

        visit "/drafts/#{draft.to_param}"
        expect(page).to_not have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
        expect(page).to_not have_button('Join this draft!')

        draft.update(state: Draft::States::ENDED)

        visit "/drafts/#{draft.to_param}"
        expect(page).to_not have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
        expect(page).to_not have_button('Join this draft!')
      end

      scenario "displays a Leave button if the user is in a waiting draft" do
        Drafter.create(draft: draft, user: user)

        visit "/drafts/#{draft.to_param}"
        expect(page).to have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
        expect(page).to have_button('Leave this draft')
      end

      scenario "clicking the Leave button leaves the draft" do
        Drafter.create(draft: draft, user: user)

        visit "/drafts/#{draft.to_param}"
        expect(page).to have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
        click_button('Leave this draft')

        expect(current_path).to eq draft_path(draft)
        expect(page).to_not have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
        expect(page).to have_button('Join this draft!')
      end

      scenario "doesn't display the Leave button if the user isn't in" do
        expect(draft.drafters.map(&:user_id)).to_not include(user.id)

        visit "/drafts/#{draft.to_param}"
        expect(page).to_not have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
        expect(page).to_not have_button('Leave this draft')
      end

      scenario "doesn't display the Leave button for non-waiting drafts" do
        Drafter.create(draft: draft, user: user)
        draft.update(state: Draft::States::DRAFTING)

        visit "/drafts/#{draft.to_param}"
        expect(page).to have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
        expect(page).to_not have_button('Leave this draft')

        draft.update(state: Draft::States::DECK_BUILDING)

        visit "/drafts/#{draft.to_param}"
        expect(page).to have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
        expect(page).to_not have_button('Leave this draft')

        draft.update(state: Draft::States::ENDED)

        visit "/drafts/#{draft.to_param}"
        expect(page).to have_css('table.drafters-list tr.row--drafter td.cell--drafter-name', text: user.name)
        expect(page).to_not have_button('Leave this draft')
      end

    end
  end
end
require 'rails_helper'

feature "UserSessions" do
  let(:user) { FactoryGirl.create(:confirmed_user) }

  scenario "is linked from the homepage" do
    visit '/'
    expect(page).to have_link('Sign in')
  end

  scenario "allows sign-in and -out of a confirmed user" do
    visit new_user_session_path
    fill_in "Username", with: user.name
    fill_in "Password", with: user.password
    click_button "Sign in"

    expect(page).to have_content "Signed in successfully"
    expect(page).to have_content "Signed in as #{user.name}"
    expect(page).to have_content "Sign out"

    click_link "Sign out"
    expect(page).to have_content "Signed out successfully"
    expect(page).to have_content "Sign up"
    expect(page).to have_content "Sign in"
  end

  feature "sign-in errors" do
    scenario "fails if the password mismatches" do
      visit new_user_session_path
      fill_in "Username", with: user.name
      fill_in "Password", with: user.password + "wrong"
      click_button "Sign in"

      expect(page).to have_content "Invalid username or password"
    end

    scenario "fails if the username doesn't exist" do
      visit new_user_session_path
      fill_in "Username", with: user.name + "wrong"
      fill_in "Password", with: user.password
      click_button "Sign in"

      expect(page).to have_content "Invalid username or password"
    end

    scenario "fails if the user is unconfirmed" do
      user = FactoryGirl.create(:user)
      visit new_user_session_path
      fill_in "Username", with: user.name
      fill_in "Password", with: user.password
      click_button "Sign in"

      expect(page).to have_content "You have to confirm your account before continuing"
    end
  end
end

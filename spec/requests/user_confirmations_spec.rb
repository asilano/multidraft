require 'spec_helper'
require 'ruby-debug'

describe "UserConfirmations" do
  it "processes sign-up (with confirmation)" do
    user = FactoryGirl.build(:user)
    visit '/'
    click_link 'Sign up'
    fill_in 'Username', with: user.name
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    fill_in 'Password confirmation', with: user.password
    click_button 'Sign up'

    email = last_email
    expect(email.to).to include user.email
    expect(email.subject).to eq 'Confirmation instructions'
    expect(email.body).to include 'You can confirm your account email through the link below:'

    # Check that the user is not confirmed yet; and can't log in
    db_user = User.where(name: user.name).first
    expect(db_user).to_not be_nil
    expect(db_user.confirmed_at).to be_nil
    visit new_user_session_url
    fill_in 'Username', with: user.name
    fill_in 'Password', with: user.password
    click_button 'Sign in'

    expect(page).to have_content 'Invalid username or password'

    # Pick up and visit the
  end
end

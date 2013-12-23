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
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
    expect(email.to).to include user.email
    expect(email.subject).to eq 'Confirmation instructions'
    expect(text_body).to include 'You can confirm your account through the link below:'

    # Check that the user is not confirmed yet; and can't log in
    db_user = User.where(name: user.name).first
    expect(db_user).to_not be_nil
    expect(db_user.confirmed_at).to be_nil
    visit new_user_session_url
    fill_in 'Username', with: user.name
    fill_in 'Password', with: user.password
    click_button 'Sign in'

    expect(page).to have_content 'You have to confirm your account before continuing.'

    # Pick up and visit the confirmation link from the confirmation email
    confirm_link = text_body.match(/http:.*$/)[0]
    visit confirm_link
    expect(page).to have_content "Your account was successfully confirmed."
    db_user = User.where(name: user.name).first
    expect(db_user).to_not be_nil
    expect(db_user.confirmed_at).to_not be_nil

    # Check login now works
    visit new_user_session_url
    fill_in 'Username', with: user.name
    fill_in 'Password', with: user.password
    click_button 'Sign in'

    expect(page).to have_content 'Signed in successfully.'
  end
end

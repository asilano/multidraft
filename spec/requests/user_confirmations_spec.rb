require 'spec_helper'

describe "UserConfirmations" do
  let(:user) { FactoryGirl.build(:user) }
  before(:each) do
    visit new_user_registration_path
    fill_in 'Username', with: user.name
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    fill_in 'Password confirmation', with: user.password
    click_button 'Sign up'
  end

  it "processes sign-up (with confirmation)" do
    email = last_email
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
    expect(email.to).to include user.email
    expect(email.subject).to eq 'Confirmation instructions'
    expect(text_body).to include 'You can confirm your account through the link below:'

    # Check that the user is not confirmed yet; and can't log in
    db_user = User.where(name: user.name).first
    expect(db_user).to_not be_nil
    expect(db_user.confirmed_at).to be_nil
    visit new_user_session_path
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
    visit new_user_session_path
    fill_in 'Username', with: user.name
    fill_in 'Password', with: user.password
    click_button 'Sign in'

    expect(page).to have_content 'Signed in successfully.'
  end

  it "doesn't time out confirmation" do
    email = last_email
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
    confirm_link = text_body.match(/http:.*$/)[0]

    Timecop.freeze(3.years.since Date.today) do
      visit confirm_link
      expect(page).to have_content "Your account was successfully confirmed."
    end
  end

  it "rejects confirmation with a bad token" do
    email = last_email
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
    confirm_link = text_body.match(/http:.*$/)[0]
    confirm_link.sub!(/confirmation_token=.*/, 'confirmation_token=invalidToken')

    visit confirm_link
    expect(page).to have_content 'Confirmation token is invalid'
  end

  it "rejects confirmation of an already-confirmed account" do
    email = last_email
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
    confirm_link = text_body.match(/http:.*$/)[0]
    visit confirm_link
    expect(page).to have_content "Your account was successfully confirmed."

    visit confirm_link
    expect(page).to have_content "Confirmation token is invalid"
  end

  it "allows resending of a lost confirmation email" do
    email = last_email
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
    confirm_link = text_body.match(/http:.*$/)[0]

    reset_email
    visit new_user_confirmation_path
    fill_in 'Email', with: user.email
    click_button 'Resend confirmation instructions'

    email = last_email
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
    confirm_link2 = text_body.match(/http:.*$/)[0]
    expect(confirm_link2).to_not eql confirm_link

    visit confirm_link
    expect(page).to have_content "Confirmation token is invalid"
    visit confirm_link2
    expect(page).to have_content "Your account was successfully confirmed."
  end

  it "prevents resending a confirmation email for an already-confirmed account" do
    email = last_email
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
    confirm_link = text_body.match(/http:.*$/)[0]
    visit confirm_link
    expect(page).to have_content "Your account was successfully confirmed."

    reset_email
    visit new_user_confirmation_path
    fill_in 'Email', with: user.email
    click_button 'Resend confirmation instructions'

    expect(page).to have_content "Email was already confirmed; please try signing in"
    expect(last_email).to be_nil
  end

  it "processes confirmation of an email address change" do
    email = last_email
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
    confirm_link = text_body.match(/http:.*$/)[0]
    visit confirm_link
    expect(page).to have_content "Your account was successfully confirmed."

    login user
    visit edit_user_registration_path
    fill_in 'Email', with: "alt.#{user.email}"
    fill_in 'Current password', with: user.password
    click_button 'Update'

    expect(page).to have_content 'You updated your account successfully, but we need to verify your new email address'
    email = last_email
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source

    expect(email.to).to include "alt.#{user.email}"
    expect(email.subject).to eq 'Confirmation instructions'
    expect(text_body).to include 'You can confirm your account through the link below:'

    visit edit_user_registration_path
    expect(page).to have_content "Currently awaiting confirmation for: alt.#{user.email}"

    confirm_link = text_body.match(/http:.*$/)[0]
    visit confirm_link
    expect(page).to have_content "Your account was successfully confirmed."

    visit edit_user_registration_path
    expect(page).to_not have_content "Currently awaiting confirmation for:"
  end
end

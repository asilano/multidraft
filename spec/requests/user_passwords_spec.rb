require 'spec_helper'

describe "UserPasswords" do
  let(:user) { FactoryGirl.create(:confirmed_user) }

  it "is linked from Sign In page" do
    visit new_user_session_url
    expect(page).to have_content 'Forgot your password?'
    click_link 'Forgot your password?'
    expect(current_url).to eql new_user_password_url
  end

  it "handles a request to reset password" do
    visit new_user_password_url
    fill_in 'Email', with: user.email
    click_button 'Send me reset password instructions'

    email = last_email
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
    expect(email.to).to include user.email
    expect(email.subject).to eq 'Reset password instructions'
    expect(text_body).to include 'Someone has requested a link to change your password.'

    # Pick up and visit the reset link from the email
    reset_link = text_body.match(/http:.*$/)[0]
    visit reset_link
    expect(page).to have_content 'Change your password'
save_and_open_page
    user.password << '111'
    fill_in 'New password', with: user.password
    fill_in 'Confirm new password', with: user.password
    click_button 'Change my password'

    # Changing the password also signs in
    expect(page).to have_content 'Your password was changed successfully. You are now signed in.'
    expect(page).to have_content "Signed in as #{user.name}"

    # Check the password really did change
    click_link 'Sign out'
    login user
  end
end
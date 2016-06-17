require 'rails_helper'

describe "UserPasswords" do
  let(:user) { FactoryGirl.create(:confirmed_user) }

  it "is linked from Sign In page" do
    visit new_user_session_path
    expect(page).to have_content 'Forgot your password?'
    click_link 'Forgot your password?'
    expect(current_path).to eql new_user_password_path
  end

  it "handles a request to reset password" do
    visit new_user_password_path
    fill_in 'Email', with: user.email
    click_button 'Send me reset password instructions'
    expect(page).to have_content 'You will receive an email with instructions about how to reset your password'

    email = last_email
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
    expect(email.to).to include user.email
    expect(email.subject).to eq 'Reset password instructions'
    expect(text_body).to include 'Someone has requested a link to change your password.'

    # Pick up and visit the reset link from the email
    reset_link = text_body.match(/http:.*$/)[0]
    visit reset_link
    expect(page).to have_content 'Change your password'

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

  describe "password reset failures" do
    it "doesn't send instructions to an unregistered user" do
      visit new_user_password_path
      fill_in 'Email', with: "alt.#{user.email}"
      click_button 'Send me reset password instructions'
      expect(page).to have_content 'Email not found'
    end

    it "doesn't accept an invalid token" do
      visit new_user_password_path
      fill_in 'Email', with: user.email
      click_button 'Send me reset password instructions'

      email = last_email
      text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source

      # Pick up and visit the reset link from the email
      reset_link = text_body.match(/http:.*$/)[0]
      reset_link.sub!(/reset_password_token=.*/, 'reset_password_token=invalidToken')
      visit reset_link
      expect(page).to have_content 'Change your password'

      user.password << '111'
      fill_in 'New password', with: user.password
      fill_in 'Confirm new password', with: user.password
      click_button 'Change my password'
      expect(page).to have_content 'Reset password token is invalid'
    end

    it "doesn't accept invalid passwords" do
      visit new_user_password_path
      fill_in 'Email', with: user.email
      click_button 'Send me reset password instructions'

      email = last_email
      text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source

      # Pick up and visit the reset link from the email
      reset_link = text_body.match(/http:.*$/)[0]
      visit reset_link
      expect(page).to have_content 'Change your password'

      fill_in 'New password', with: user.password
      click_button 'Change my password'
      expect(page).to have_content "Password confirmation doesn't match Password"

      fill_in 'New password', with: user.password
      fill_in 'Confirm new password', with: (user.password + '111')
      click_button 'Change my password'
      expect(page).to have_content "Password confirmation doesn't match Password"

      fill_in 'New password', with: 'abc'
      fill_in 'Confirm new password', with: 'abc'
      click_button 'Change my password'
      expect(page).to have_content "Password is too short (minimum is 5 characters)"

      user.password << '111'
      fill_in 'New password', with: user.password
      fill_in 'Confirm new password', with: user.password
      click_button 'Change my password'
    end
  end
end
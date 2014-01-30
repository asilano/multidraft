require 'spec_helper'

describe "UserRegistrations" do
  it "is linked from the homepage" do
    visit '/'
    expect(page).to have_link('Sign up')
  end

  it "processes sign-up (not confirmation)" do
    user = FactoryGirl.build(:user)
    visit '/'
    click_link 'Sign up'
    fill_in 'Username', with: user.name
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    fill_in 'Password confirmation', with: user.password
    click_button 'Sign up'

    expect(page).to have_content 'A message with a confirmation link has been sent to your email address. Please open the link to activate your account.'
    email = last_email
    text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source

    expect(email.to).to include user.email
    expect(email.subject).to eq 'Confirmation instructions'
    expect(text_body).to include 'You can confirm your account through the link below:'
  end

  describe "validation errors on create" do
    let(:user) { FactoryGirl.build(:user) }
    before(:each) do
      visit new_user_registration_path
    end

    it "fails if username is missing" do
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      fill_in 'Password confirmation', with: user.password
      click_button 'Sign up'

      expect(page).to have_content "Username can't be blank"
    end

    it "fails if email is missing or invalid" do
      fill_in 'Username', with: user.name
      fill_in 'Password', with: user.password
      fill_in 'Password confirmation', with: user.password
      click_button 'Sign up'
      expect(page).to have_content "Email can't be blank"

      fill_in 'Email', with: 'lookMaNoAtSign'
      click_button 'Sign up'
      expect(page).to have_content "Email is invalid"

      fill_in 'Email', with: 'lookMaNo@TLD'
      click_button 'Sign up'
      expect(page).to have_content "Email is invalid"

      fill_in 'Email', with: 'lookMa spaces@example.com'
      click_button 'Sign up'
      expect(page).to have_content "Email is invalid"

      # Corner case - allow '+' for gmail-style disposables
      fill_in 'Email', with: 'lookMa+aPlus@example.com'
      fill_in 'Username', with: user.name
      fill_in 'Password', with: user.password
      fill_in 'Password confirmation', with: user.password
      click_button 'Sign up'
      expect(page).to have_content "A message with a confirmation link has been sent to your email address."
    end

    it "fails if password is missing or invalid" do
      fill_in 'Username', with: user.name
      fill_in 'Email', with: user.email
      click_button 'Sign up'
      expect(page).to have_content "Password can't be blank"

      fill_in 'Password', with: user.password
      click_button 'Sign up'
      expect(page).to have_content "Password doesn't match confirmation"

      fill_in 'Password', with: user.password
      fill_in 'Password confirmation', with: (user.password + '111')
      click_button 'Sign up'
      expect(page).to have_content "Password doesn't match confirmation"

      fill_in 'Password', with: 'abc'
      fill_in 'Password confirmation', with: 'abc'
      click_button 'Sign up'
      expect(page).to have_content "Password is too short (minimum is 5 characters)"
    end

    it "fails if username already exists modulo case" do
      fill_in 'Username', with: user.name
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      fill_in 'Password confirmation', with: user.password
      click_button 'Sign up'

      visit new_user_registration_path
      name = case user.name
              when /[a-z]/
                user.name.upcase
              when /[A-Z]/
                user.name.downcase
              else
                raise "Can't test case insensitivity with #{user.name}"
              end
      fill_in 'Username', with: name
      fill_in 'Email', with: "another.#{user.email}"
      fill_in 'Password', with: user.password
      fill_in 'Password confirmation', with: user.password
      click_button 'Sign up'
      expect(page).to have_content "Username has already been taken"
    end
  end

  describe "edit registrations" do
    let(:user) { FactoryGirl.create(:confirmed_user) }
    before(:each) { login user }

    it "should be linked from the homepage" do
      visit '/'
      expect(page).to have_link(user.name)
      click_link user.name
      expect(current_url).to eql edit_user_registration_url
    end

    it "should let you change your username" do
      visit edit_user_registration_path
      fill_in 'Username', with: "#{user.name}AlterEgo"
      click_button 'Update'

      expect(page).to have_content 'You updated your account successfully'
      click_link 'Sign out'
      login user, fail: true
      user.name = "#{user.name}AlterEgo"
      login user
    end

    it "should let you change your email address" do
      visit edit_user_registration_path
      fill_in 'Email', with: "alt.#{user.email}"
      click_button 'Update'

      expect(page).to have_content 'You updated your account successfully, but we need to verify your new email address'
      email = last_email
      text_body = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source

      expect(email.to).to include "alt.#{user.email}"
      expect(email.subject).to eq 'Confirmation instructions'
      expect(text_body).to include 'You can confirm your account through the link below:'
    end

    it "should let you change your password" do
      visit edit_user_registration_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: "another#{user.password}"
      fill_in 'Password confirmation', with: "another#{user.password}"
      click_button 'Update'

      expect(page).to have_content 'You updated your account successfully'
      click_link 'Sign out'
      login user, fail: true
      user.password = "another#{user.password}"
      login user
    end

    describe "validation errors on edit" do
      before(:each) { visit edit_user_registration_path }

      it "fails if email is missing or invalid" do
        fill_in 'Email', with: ''
        click_button 'Update'
        expect(page).to have_content "Email can't be blank"

        fill_in 'Email', with: 'lookMaNoAtSign'
        click_button 'Update'
        expect(page).to have_content "Email is invalid"

        fill_in 'Email', with: 'lookMaNo@TLD'
        click_button 'Update'
        expect(page).to have_content "Email is invalid"

        fill_in 'Email', with: 'lookMa spaces@example.com'
        click_button 'Update'
        expect(page).to have_content "Email is invalid"

        # Corner case - allow '+' for gmail-style disposables
        fill_in 'Email', with: 'lookMa+aPlus@example.com'
        click_button 'Update'
        expect(page).to have_content "You updated your account successfully, but we need to verify"
      end

      it "fails if new password is missing or invalid" do
        fill_in 'Password', with: user.password + "new"
        click_button 'Update'
        expect(page).to have_content "Password doesn't match confirmation"

        fill_in 'Password', with: user.password + "new"
        fill_in 'Password confirmation', with: (user.password + 'new111')
        click_button 'Update'
        expect(page).to have_content "Password doesn't match confirmation"

        fill_in 'Password', with: 'abc'
        fill_in 'Password confirmation', with: 'abc'
        click_button 'Update'
        expect(page).to have_content "Password is too short (minimum is 5 characters)"
      end
    end
  end

  describe "tests requiring JavaScript", js: true do
    self.use_transactional_fixtures = false

    it "should allow the user to destroy their account" do
      leaving_user = FactoryGirl.create(:confirmed_user)
      login leaving_user
      visit edit_user_registration_path
      click_button 'Delete my account'
      page.driver.browser.switch_to.alert.accept

      expect(page).to have_content 'Your account was successfully cancelled.'
      expect(User.where(name: leaving_user.name).first).to be_nil
    end
  end
end

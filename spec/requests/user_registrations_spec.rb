require 'spec_helper'

describe "UserRegistrations" do
  it "is linked from the homepage" do
    visit '/'
    expect(page).to have_link('Sign up')
    expect(page).to have_link('Sign in')
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

    expect(email.to).to include user.email
    expect(email.subject).to eq 'Confirmation instructions'
    expect(email.body).to include 'You can confirm your account email through the link below:'
  end

  describe "validation errors" do
    let(:user) { FactoryGirl.build(:user) }
    before(:each) do
      visit new_user_registration_url
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
  end
end

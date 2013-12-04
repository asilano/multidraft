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
end

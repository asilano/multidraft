require 'spec_helper'

describe "UserRegistrations" do
  it "is linked from the homepage" do
    visit '/'#root_path
    expect(page).to have_link('Sign up')
    expect(page).to have_link('Sign in')
  end
end

require 'rails_helper'

describe 'UserSessions requests' do
  let(:user) { FactoryGirl.create(:user) }
  before(:each) { user.confirm }

  it "permits visiting the sign-in page" do
    get new_user_session_path

    expect(response.status).to eq 200
    expect(response).to render_template :new
  end

  it "handles log-in" do
    post user_session_path, user: { name: user.name, password: user.password }

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include('Signed in successfully')
    expect(response.body).to include(user.name)
    expect(response.body).to_not include('Sign in')
  end

  it "handles failed log-in" do
    post user_session_path, user: { name: user.name, password: user.password + 'wrong' }

    expect(response.status).to eq 200
    expect(response).to render_template :new
    expect(response.body).to include('Invalid username or password')
  end

  it "treats log-out as if it had worked" do
    delete destroy_user_session_path

    expect(response.status).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include('Sign in')
  end

  describe 'when logged in' do
    before(:each) { login user }

    it "redirects away from the sign-in page" do
      get new_user_session_path

      expect(response.status).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to_not include('Sign in')
      expect(response.body).to include(user.name)
    end

    it "handles log-in" do
      post user_session_path, user: { name: user.name, password: user.password }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('You are already signed in')
      expect(response.body).to include(user.name)
      expect(response.body).to_not include('Sign in')
    end

    it "handles failed log-in" do
      post user_session_path, user: { name: user.name, password: user.password + 'wrong' }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('You are already signed in')
      expect(response.body).to include(user.name)
      expect(response.body).to_not include('Sign in')
    end

    it "handles log-out" do
      delete destroy_user_session_path

      expect(response.status).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('Sign in')
      expect(response.body).to include('Signed out successfully')
    end
  end
end
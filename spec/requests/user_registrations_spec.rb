require 'rails_helper'

describe 'UserRegistrations requests' do
  it "permits visiting the sign-up page" do
    get new_user_registration_path

    expect(response.status).to eq 200
    expect(response).to render_template :new
  end

  # Cancelling sign-up is mostly to back out of an Open-ID link
  it "redisplays the sign-up page on cancelling" do
    get cancel_user_registration_path

    expect(response.status).to redirect_to(new_user_registration_path)
    follow_redirect!
    expect(response).to render_template :new
  end

  # Successful registration redirects to index while awaiting confirmation
  it "redirects to root and mentions confirmation when adding a new user" do
    user = FactoryGirl.build(:user)
    post user_registration_path, user: { name: user.name,
                                         email: user.email,
                                         password: user.password,
                                         password_confirmation: user.password }

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include('a confirmation link has been sent')
  end

  it "displays the new user page at the root address when adding a user fails" do
    post user_registration_path, user: { email: 'bad-email', password_confirmation: 'wrong' }

    expect(response.status).to eq 200
    expect(response).to render_template :new
    expect(response.body).to include("Username can't be blank")
    expect(response.body).to include("Password can't be blank")
    expect(response.body).to include("Email is invalid")
    expect(response.body).to include("Password confirmation doesn't match Password")
  end

  describe 'requiring an existing user' do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) { user.confirm }

    it "prevents visiting the edit page when not logged in" do
      get edit_user_registration_path, id: user.to_param

      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!
      expect(response.body).to include('You need to sign in or sign up before continuing.')
    end

    describe 'when logged in' do
      before(:each) { login user }
      it "permits visiting your edit page" do
        get edit_user_registration_path, id: user.to_param

        expect(response.status).to eq 200
        expect(response).to render_template :edit
      end

      it 'updates by PUT' do
        put user_registration_path, user: { name: user.name + "Foo" }

        expect(response).to redirect_to(edit_user_registration_path)
        follow_redirect!
        expect(response.body).to include('You updated your account successfully')
      end

      it 'updates by PATCH' do
        patch user_registration_path, user: { name: user.name + "Foo" }

        expect(response).to redirect_to(edit_user_registration_path)
        follow_redirect!
        expect(response.body).to include('You updated your account successfully')
      end

      it "displays the edit user page at the root address when adding a user fails" do
        patch user_registration_path, user: { email: 'bad-email', password_confirmation: 'wrong' }

        expect(response.status).to eq 200
        expect(response).to render_template :edit
        expect(response.body).not_to include("Username can't be blank")
        expect(response.body).to include("Password can't be blank")
        expect(response.body).to include("Email is invalid")
        expect(response.body).to include("Password confirmation doesn't match Password")
      end

      it "deletes by DELETE" do
        delete user_registration_path

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include('Your account was successfully cancelled')
      end
    end
  end

end
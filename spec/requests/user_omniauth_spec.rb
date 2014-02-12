require 'spec_helper'

describe "Sign-up and Sign-in by OmniAuth" do
  before(:all) { OmniAuth.config.test_mode = true }

  describe "OpenID" do
    it "should not have any special links" do
      visit '/'
      expect(page).not_to have_content(/OpenID/i)
    end

    describe "sign-up" do
      let(:user) { FactoryGirl.build(:user) }
      before(:each) do
        OmniAuth.config.mock_auth[:open_id] = OmniAuth::AuthHash.new({
          :provider => 'open_id',
          :uid => 'http://pretend.openid.example.com?id=12345',
        })
      end

      it "should make use of the standard Sign Up form (no JS)" do
        visit new_user_registration_path
        expect(page).to have_content "Sign up using OpenID"
        expect(page).to have_content "If you already have an account with one of these providers"
        expect(page).to have_content('manually enter your OpenID')
        expect(page).to have_field('openid_url')

        expect(page).to have_field('user[name]')
        expect(page).to have_field('user[email]')
        expect(page).to have_field('user[password]')
        expect(page).to have_field('user[password_confirmation]')
      end

      it "should still require username, but not email" do
        visit new_user_registration_path
        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'

        expect(page).not_to have_content "Sign up using OpenID"
        expect(page).to have_content "Your OpenID authentication succeeded, but we still need some extra details to complete sign up"
        fill_in 'Username', with: ''
        fill_in 'Email', with: ''
        click_button 'Sign up'

        expect(page).to have_content "Username can't be blank"
        expect(page).to_not have_content "Email can't be blank"
      end

      it "should persist the OpenID to the database" do
        visit new_user_registration_path
        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'
        fill_in 'Username', with: user.name
        fill_in 'Email', with: user.email
        click_button 'Sign up'

        expect(page).to have_content 'Welcome! You have signed up successfully.'
        expect(last_email).to be_nil

        saved_user = User.where(:name => user.name).includes(:authentications).first
        expect(saved_user).to_not be_nil
        expect(saved_user.authentications[0].uid).to eql OmniAuth.config.mock_auth[:open_id][:uid]
        expect(saved_user.authentications[0].provider).to eql 'open_id'
      end

      describe "with extra info from OpenID response" do
        it "should make use of a supplied email" do
          OmniAuth.config.mock_auth[:open_id][:info] = {
            :email => user.email
          }

          visit new_user_registration_path
          fill_in 'openid_url', with: 'http://pretend.openid.example.com'
          click_button 'submit_openid'

          expect(find_field('Email').value).to eql user.email
        end

        it "should make use of a supplied nickname" do
          OmniAuth.config.mock_auth[:open_id][:info] = {
            :nickname => user.name
          }

          visit new_user_registration_path
          fill_in 'openid_url', with: 'http://pretend.openid.example.com'
          click_button 'submit_openid'

          expect(find_field('Username').value).to eql user.name
        end

        it "should make use fo a supplied fullname" do
          OmniAuth.config.mock_auth[:open_id][:info] = {
            :name => user.name + ' the First'
          }

          visit new_user_registration_path
          fill_in 'openid_url', with: 'http://pretend.openid.example.com'
          click_button 'submit_openid'

          expect(find_field('Username').value).to eql(user.name + 'TheFirst')

          # Clear down
          visit cancel_user_registration_path
          OmniAuth.config.mock_auth[:open_id][:info].delete :name
          OmniAuth.config.mock_auth[:open_id][:info] = {
            :fullname => user.name + ' the Second'
          }

          visit new_user_registration_path
          fill_in 'openid_url', with: 'http://pretend.openid.example.com'
          click_button 'submit_openid'

          expect(find_field('Username').value).to eql(user.name + 'TheSecond')
        end

        it "should make use of a supplied firstname, lastname" do
          OmniAuth.config.mock_auth[:open_id][:info] = {
            :first_name => 'Zaphod',
            :last_name => 'beeblebroX'
          }

          visit new_user_registration_path
          fill_in 'openid_url', with: 'http://pretend.openid.example.com'
          click_button 'submit_openid'

          expect(find_field('Username').value).to eql 'ZaphodBeeblebroX'
        end

        it "should make use of a supplied firstname only" do
          OmniAuth.config.mock_auth[:open_id][:info] = {
            :first_name => 'arthur'
          }

          visit new_user_registration_path
          fill_in 'openid_url', with: 'http://pretend.openid.example.com'
          click_button 'submit_openid'

          expect(find_field('Username').value).to eql 'Arthur'
        end

        it "should make use of a supplied lastname only" do
          OmniAuth.config.mock_auth[:open_id][:info] = {
            :last_name => 'PrEfEcT'
          }

          visit new_user_registration_path
          fill_in 'openid_url', with: 'http://pretend.openid.example.com'
          click_button 'submit_openid'

          expect(find_field('Username').value).to eql 'PrEfEcT'
        end

        it "should handle the supplied email already existing" do
          user.save
          OmniAuth.config.mock_auth[:open_id][:info] = {
            :email => user.email
          }

          visit new_user_registration_path
          fill_in 'openid_url', with: 'http://pretend.openid.example.com'
          click_button 'submit_openid'

          expect(find_field('Email').value).to eql user.email
          expect(page).not_to have_content 'prohibited this User from being saved'
          expect(page).to have_content 'Email has already been taken'
        end

        it "should handle the supplied username already existing" do
          user.save
          OmniAuth.config.mock_auth[:open_id][:info] = {
            :name => user.name
          }

          visit new_user_registration_path
          fill_in 'openid_url', with: 'http://pretend.openid.example.com'
          click_button 'submit_openid'

          expect(find_field('Username').value).to eql user.name
          expect(page).not_to have_content 'prohibited this User from being saved'
          expect(page).to have_content 'Username has already been taken'
        end
      end

      it "should handle cancelling an in-progress registration" do
        OmniAuth.config.mock_auth[:open_id][:info] = {
          :email => user.email,
          :name => user.name
        }

        visit new_user_registration_path
        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'

        expect(find_field('Email').value).to eql user.email
        expect(find_field('Username').value).to eql user.name
        expect(page).not_to have_content "Sign up using OpenID"
        expect(page).to have_content "Your OpenID authentication succeeded, but we still need some extra details to complete sign up"
        expect(page).to have_content "This account will be associated with an OpenID provider"

        click_link 'Cancel sign up'
        expect(find_field('Email').value).to be_blank
        expect(find_field('Username').value).to be_blank
        expect(page).to have_content "Sign up using OpenID"
        expect(page).not_to have_content "Your OpenID authentication succeeded, but we still need some extra details to complete sign up"
        expect(page).not_to have_content "This account will be associated with an OpenID provider"
      end

      it "should allow a user to sign up with password and email" do
        visit new_user_registration_path
        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'
        fill_in 'Username', with: user.name
        fill_in 'Email', with: user.email
        fill_in 'Password', with: user.password
        click_button 'Sign up'

        expect(page).to have_content "Password doesn't match confirmation"

        fill_in 'Password', with: user.password
        fill_in 'Password confirmation', with: user.password
        click_button 'Sign up'
        expect(page).to have_content 'Welcome! You have signed up successfully.'
      end

      it "should allow a user to sign up without password or email" do
        visit new_user_registration_path
        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'
        fill_in 'Username', with: user.name
        fill_in 'Email', with: ''
        click_button 'Sign up'

        expect(page).to have_content 'Welcome! You have signed up successfully.'
      end

      it "should handle a failure response" do
        OmniAuth.config.mock_auth[:open_id] = :unexpected_moose

        visit new_user_registration_path
        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'

        expect(page).to have_content 'Could not authenticate you from OpenID for the following reason: "Unexpected moose"'
        expect(page).to have_content "Sign up using OpenID"
        expect(page).to have_field('openid_url')

        expect(page).to have_field('user[name]')
        expect(page).to have_field('user[email]')
        expect(page).to have_field('user[password]')
        expect(page).to have_field('user[password_confirmation]')
      end

      describe "making use of javascript", :js => true do
        it "should support manual entry of OpenID" do
          visit new_user_registration_path

          expect(page).to have_content('Sign up using OpenID')
          expect(page).not_to have_content('manually enter your OpenID')
          expect(page).not_to have_field('openid_url')
          expect(page).to have_link("Sign up with OpenID")

          click_link 'Sign up with OpenID'
          expect(page).to have_field('openid_url')
          fill_in 'openid_url', with: 'http://pretend.openid.example.com'
          click_button 'js_submit_openid'

          expect(page).not_to have_content "Sign up using OpenID"
          expect(page).to have_content "Your OpenID authentication succeeded"
        end

        %w(Google Yahoo StackExchange Steam).each do |provider|
          it "should support #{provider} with no parameter" do
            visit new_user_registration_path

            expect(page).to have_content('Sign up using OpenID')
            expect(page).not_to have_content('manually enter your OpenID')
            expect(page).not_to have_field('openid_url')
            expect(page).to have_link("Sign up with #{provider}")
            click_link "Sign up with #{provider}"

            expect(page).not_to have_content "Sign up using OpenID"
            expect(page).to have_content "Your OpenID authentication succeeded"
          end
        end

        %w(LiveJournal).each do |provider|
          it "should support #{provider} with a parameter" do
            visit new_user_registration_path

            expect(page).to have_content('Sign up using OpenID')
            expect(page).not_to have_content('manually enter your OpenID')
            expect(page).not_to have_field('openid_url')
            expect(page).to have_link("Sign up with #{provider}")

            click_link "Sign up with #{provider}"
            expect(page).to have_field('openid_param')
            fill_in 'openid_param', with: 'my_username'
            click_button 'js_submit_openid'

            expect(page).not_to have_content "Sign up using OpenID"
            expect(page).to have_content "Your OpenID authentication succeeded"
          end
        end

        it "should clear the form between choices" do
          visit new_user_registration_path

          click_link 'Sign up with OpenID'
          expect(page).to have_field('openid_url')

          click_link "Sign up with LiveJournal"
          expect(page).not_to have_field('openid_url')
          expect(page).to have_field('openid_param')

          click_link 'Sign up with OpenID'
          expect(page).to have_field('openid_url')
          expect(page).not_to have_field('openid_param')
        end
      end
    end

    describe "sign-in" do
      let(:open_id_user) { FactoryGirl.create :open_id_user }
      let(:non_oid_user) { FactoryGirl.create :confirmed_user }
      before(:each) do
        OmniAuth.config.mock_auth[:open_id] = OmniAuth::AuthHash.new({
          :provider => open_id_user.authentications[0].provider,
          :uid => open_id_user.authentications[0].uid,
        })
      end

      it "should allow an existing OpenID user to sign in" do
        visit new_user_session_path
        expect(page).to have_content "Sign in using OpenID"
        expect(page).to have_content "If you already have an account with one of these providers"
        expect(page).to have_content('manually enter your OpenID')
        expect(page).to have_field('openid_url')

        expect(page).to have_field('user[name]')
        expect(page).to have_field('user[password]')

        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'
        expect(page).to have_content "Successfully authenticated from OpenID account"
        expect(page).to have_content "Signed in as #{open_id_user.name}"
        expect(page).to have_content "Sign out"
      end

      it "should redirect to sign-up form if an unknown UID is given" do
        visit new_user_session_path
        expect(page).to have_content "Sign in using OpenID"
        expect(page).to have_content "If you already have an account with one of these providers"
        expect(page).to have_content('manually enter your OpenID')
        expect(page).to have_field('openid_url')

        expect(page).to have_field('user[name]')
        expect(page).to have_field('user[password]')

        OmniAuth.config.mock_auth[:open_id][:uid] += "OtherUser"

        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'
        expect(current_url).to eql new_user_registration_url
        expect(page).to have_content "Your OpenID authentication succeeded, but we still need some extra details to complete sign up"
      end

      it "should not allow an existing OpenID user to sign in if there is an OpenID error" do
        visit new_user_session_path
        expect(page).to have_content "Sign in using OpenID"
        expect(page).to have_content "If you already have an account with one of these providers"
        expect(page).to have_content('manually enter your OpenID')
        expect(page).to have_field('openid_url')

        expect(page).to have_field('user[name]')
        expect(page).to have_field('user[password]')

        OmniAuth.config.mock_auth[:open_id] = :illegal_penguin
        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'
        expect(current_url).to eql new_user_session_url
        expect(page).to have_content 'Could not authenticate you from OpenID for the following reason: "Illegal penguin"'
      end

      describe "making use of javascript", :js => true do
        it "should sign in with manual entry of OpenID" do
          visit new_user_session_path

          expect(page).to have_content('Sign in using OpenID')
          expect(page).not_to have_content('manually enter your OpenID')
          expect(page).not_to have_field('openid_url')
          expect(page).to have_link("Sign in with OpenID")

          click_link 'Sign in with OpenID'
          expect(page).to have_field('openid_url')
          fill_in 'openid_url', with: 'http://pretend.openid.example.com'
          click_button 'js_submit_openid'

          expect(page).to have_content "Successfully authenticated from OpenID account"
          expect(page).to have_content "Signed in as #{open_id_user.name}"
          expect(page).to have_content "Sign out"
        end

        %w(Google Yahoo StackExchange Steam).each do |provider|
          it "should sign in with #{provider} with no parameter" do
            visit new_user_session_path

            expect(page).to have_content('Sign in using OpenID')
            expect(page).not_to have_content('manually enter your OpenID')
            expect(page).not_to have_field('openid_url')
            expect(page).to have_link("Sign in with #{provider}")
            click_link "Sign in with #{provider}"

            expect(page).to have_content "Successfully authenticated from OpenID account"
            expect(page).to have_content "Signed in as #{open_id_user.name}"
            expect(page).to have_content "Sign out"
          end
        end

        %w(LiveJournal).each do |provider|
          it "should sign in with #{provider} with a parameter" do
            visit new_user_session_path

            expect(page).to have_content('Sign in using OpenID')
            expect(page).not_to have_content('manually enter your OpenID')
            expect(page).not_to have_field('openid_url')
            expect(page).to have_link("Sign in with #{provider}")

            click_link "Sign in with #{provider}"
            expect(page).to have_field('openid_param')
            fill_in 'openid_param', with: 'my_username'
            click_button 'js_submit_openid'

            expect(page).to have_content "Successfully authenticated from OpenID account"
            expect(page).to have_content "Signed in as #{open_id_user.name}"
            expect(page).to have_content "Sign out"
          end
        end
      end
    end

    describe "adding and removing OpenID on existing accounts" do
      let(:open_id_user) { FactoryGirl.create :open_id_user }
      let(:non_oid_user) { FactoryGirl.create :confirmed_user }

      it "should allow an existing non-OpenID user to add an OpenID" do
        login non_oid_user
        visit edit_user_registration_path

        expect(page).not_to have_content('optional for OpenID users')
        expect(page).not_to have_content "This account is linked with the following authentication methods"
        expect(page).to have_content('Add an OpenID account')
        expect(page).to have_content "If you already have an account with one of these providers"
        expect(page).to have_content('manually enter your OpenID')
        expect(page).to have_field('openid_url')

        OmniAuth.config.mock_auth[:open_id] = OmniAuth::AuthHash.new({
          :provider => open_id_user.authentications[0].provider,
          :uid => open_id_user.authentications[0].uid + "other",
        })

        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'

        expect(page).to have_content "Successfully authenticated from OpenID account"
        expect(page).to have_content "This account is linked with the following authentication methods"
        expect(page).to have_content "http://pretend.openid.example.com"
        expect(page).to have_link 'Remove', count: 1
      end

      it "should allow an existing OpenID user to add another OpenID" do
        login open_id_user
        visit edit_user_registration_path

        expect(page).to have_content('optional for OpenID users')
        expect(page).to have_content "This account is linked with the following authentication methods"
        expect(page).to have_content "http://pretend.openid.example.com"
        expect(page).to have_link 'Remove', count: 1
        expect(page).to have_content('Add an OpenID account')
        expect(page).to have_content "If you already have an account with one of these providers"
        expect(page).to have_content('manually enter your OpenID')
        expect(page).to have_field('openid_url')

        OmniAuth.config.mock_auth[:open_id] = OmniAuth::AuthHash.new({
          :provider => open_id_user.authentications[0].provider,
          :uid => open_id_user.authentications[0].uid + "other",
        })

        fill_in 'openid_url', with: 'http://fake.openid.example.com'
        click_button 'submit_openid'

        expect(page).to have_content "Successfully authenticated from OpenID account"
        expect(page).to have_content "This account is linked with the following authentication methods"
        expect(page).to have_content "http://pretend.openid.example.com"
        expect(page).to have_content "http://fake.openid.example.com"
        expect(page).to have_link 'Remove', count: 2
      end

      it "should allow an existing multi-OpenID user to remove an OpenID" do
        auth_two = FactoryGirl.create(:second_openid, user: open_id_user)
        login open_id_user
        visit edit_user_registration_path

        expect(page).to have_content "This account is linked with the following authentication methods"
        expect(page).to have_content "http://pretend.openid.example.com"
        expect(page).to have_content "Fake OpenID"
        expect(page).to have_link 'Remove', count: 2

        page.find('.auth-nickname', text: 'Fake OpenID').find(:xpath, '..').click_link('Remove')

        expect(page).to have_content "Successfully removed authentication from Fake OpenID"
        expect(page).to have_content "http://pretend.openid.example.com"
        expect(page).to have_link 'Remove', count: 1
      end

      it "should allow an existing OpenID user to remove the last OpenID if they have an email and password" do
        login open_id_user
        open_id_user.encrypted_password = ''
        open_id_user.save!

        # Need to re-login, because changing the password as someone else logs out
        OmniAuth.config.mock_auth[:open_id] = OmniAuth::AuthHash.new({
          :provider => open_id_user.authentications[0].provider,
          :uid => open_id_user.authentications[0].uid,
        })
        visit new_user_session_path
        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'

        visit edit_user_registration_path
        expect(page).to have_content "This account is linked with the following authentication methods"
        expect(page).to have_content "http://pretend.openid.example.com"
        expect(page).to have_link 'Remove', count: 1

        click_link 'Remove'
        expect(page).to have_content 'You cannot remove your last authentication method without having an email address and password set.'

        # Set password, and blank email
        open_id_user.password = 'secret'
        open_id_user.password_confirmation = 'secret'
        open_id_user.email = ''
        open_id_user.save!

        # Re-login again
        visit new_user_session_path
        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'

        visit edit_user_registration_path
        click_link 'Remove'
        expect(page).to have_content 'You cannot remove your last authentication method without having an email address and password set.'

        # Set email. Removal should work
        open_id_user.email = "#{open_id_user.name}@example.com"
        open_id_user.save!
        open_id_user.confirm!

        click_link 'Remove'
        expect(page).to have_content "Successfully removed authentication from http://pretend.openid.example.com"
        expect(page).not_to have_content('optional for OpenID users')
        expect(page).not_to have_content "This account is linked with the following authentication methods"
      end

      it "should be a no-op if a logged-in user adds an existing OpenID they own" do
        login open_id_user
        visit edit_user_registration_path

        OmniAuth.config.mock_auth[:open_id] = OmniAuth::AuthHash.new({
          :provider => open_id_user.authentications[0].provider,
          :uid => open_id_user.authentications[0].uid,
        })

        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'

        expect(page).to have_content "This account is already linked with that OpenID account"
        expect(page).to have_content "This account is linked with the following authentication methods"
        expect(page).to have_content "http://pretend.openid.example.com"
        expect(page).to have_link 'Remove', count: 1
      end

      it "should warn and fail if a logged-in user adds an existing OpenID they don't own" do
        login non_oid_user
        visit edit_user_registration_path

        OmniAuth.config.mock_auth[:open_id] = OmniAuth::AuthHash.new({
          :provider => open_id_user.authentications[0].provider,
          :uid => open_id_user.authentications[0].uid,
        })

        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'

        expect(page).to have_content "Another account is already linked with that OpenID account"
        expect(page).not_to have_content('optional for OpenID users')
        expect(page).not_to have_content "This account is linked with the following authentication methods"
      end

      describe "by javascript", :js => true do
        before(:each) do
          OmniAuth.config.mock_auth[:open_id] = OmniAuth::AuthHash.new({
            :provider => open_id_user.authentications[0].provider,
            :uid => open_id_user.authentications[0].uid + "other",
          })
        end

        it "should allow adding a manual URL" do
          login non_oid_user
          visit edit_user_registration_path

          expect(page).not_to have_content('optional for OpenID users')
          expect(page).to have_content('Add an OpenID account')
          expect(page).not_to have_content('manually enter your OpenID')
          expect(page).not_to have_field('openid_url')
          expect(page).to have_link("Authenticate with OpenID")

          click_link 'Authenticate with OpenID'
          expect(page).to have_field('openid_url')
          fill_in 'openid_url', with: 'http://pretend.openid.example.com'
          click_button 'js_submit_openid'

          expect(page).to have_content "Successfully authenticated from OpenID account"
          expect(page).to have_content "This account is linked with the following authentication methods"
          expect(page).to have_content "http://pretend.openid.example.com"
          expect(page).to have_link 'Remove', count: 1
        end

        %w(Google Yahoo StackExchange Steam).each do |provider|
          it "should allow adding #{provider} with no parameter" do
            login open_id_user
            visit edit_user_registration_path

            expect(page).to have_content('optional for OpenID users')
            expect(page).to have_content "This account is linked with the following authentication methods"
            expect(page).to have_content "http://pretend.openid.example.com"
            expect(page).to have_link 'Remove', count: 1
            expect(page).to have_link("Authenticate with #{provider}")
            click_link "Authenticate with #{provider}"

            expect(page).to have_content "Successfully authenticated from OpenID account"
            expect(page).to have_content "This account is linked with the following authentication methods"
            expect(page).to have_content "http://pretend.openid.example.com"
            expect(page).to have_css('.auth-nickname', :text => provider)
            expect(page).to have_link 'Remove', count: 2
          end
        end
        %w(LiveJournal).each do |provider|
          it "should allow adding #{provider} with a parameter" do
            login non_oid_user
            visit edit_user_registration_path

            expect(page).not_to have_content('optional for OpenID users')
            expect(page).to have_content('Add an OpenID account')
            expect(page).not_to have_content('manually enter your OpenID')
            expect(page).not_to have_field('openid_url')
            expect(page).to have_link("Authenticate with #{provider}")

            click_link "Authenticate with #{provider}"
            expect(page).to have_field('openid_param')
            fill_in 'openid_param', with: 'my_username'
            click_button 'js_submit_openid'

            expect(page).to have_content "Successfully authenticated from OpenID account"
            expect(page).to have_content "This account is linked with the following authentication methods"
            expect(page).to have_css('.auth-nickname', :text => provider)
            expect(page).to have_link 'Remove', count: 1
          end
        end

        it "should handle removing an OpenID" do
          auth_two = FactoryGirl.create(:second_openid, user: open_id_user)
          login open_id_user
          visit edit_user_registration_path

          expect(page).to have_content "This account is linked with the following authentication methods"
          expect(page).to have_content "http://pretend.openid.example.com"
          expect(page).to have_content "Fake OpenID"
          expect(page).to have_link 'Remove', count: 2

          page.find('.auth-nickname', text: 'Fake OpenID').find(:xpath, '..').click_link('Remove')

          expect(page).to have_content "http://pretend.openid.example.com"
          expect(page).to have_link 'Remove', count: 1
        end
      end
    end

    describe "adding and removing password to OpenID account" do
      let(:user) do
        user = FactoryGirl.create :open_id_user
        user.encrypted_password = ""
        user.save
        user
      end

      before(:each) do
        OmniAuth.config.mock_auth[:open_id] = OmniAuth::AuthHash.new({
          :provider => user.authentications[0].provider,
          :uid => user.authentications[0].uid,
        })

        visit new_user_session_path
        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'
        expect(page).to have_content "Signed in as #{user.name}"
      end

      it "should allow an existing OpenID user with no password to add one, then remove it" do
        visit edit_user_registration_path

        expect(page).not_to have_field 'Remove password'
        fill_in 'Password', with: user.password
        fill_in 'Password confirmation', with: user.password
        click_button 'Update'
        expect(page).to have_content 'You updated your account successfully'

        # Attempt to login with password now
        click_link 'Sign out'
        login user

        # Now remove the password
        visit edit_user_registration_path

        expect(page).to have_field 'Remove password'
        check 'Remove password'
        click_button 'Update'
        expect(page).to have_content 'You updated your account successfully'

        # Attempt to login with password - should fail
        click_link 'Sign out'
        login user, fail: true
      end
    end

    describe "adding and removing email to OpenID account" do
      let(:user) do
        user = FactoryGirl.create :open_id_user
        user.email = ""
        user.save
        user
      end

      before(:each) do
        OmniAuth.config.mock_auth[:open_id] = OmniAuth::AuthHash.new({
          :provider => user.authentications[0].provider,
          :uid => user.authentications[0].uid,
        })

        visit new_user_session_path
        fill_in 'openid_url', with: 'http://pretend.openid.example.com'
        click_button 'submit_openid'
        expect(page).to have_content "Signed in as #{user.name}"
      end

      it "should allow an existing OpenID user with no email to add one, then remove it" do
        visit edit_user_registration_path

        fill_in 'Email', with: user.email
        click_button 'Update'
        expect(page).to have_content 'You updated your account successfully'

        # Now remove the password
        visit edit_user_registration_path
        fill_in 'Email', with: ''
        click_button 'Update'
        expect(page).to have_content 'You updated your account successfully'
      end
    end
  end
end
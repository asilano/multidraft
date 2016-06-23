module LoginMacros
  module Feature
    def login(user, opts = {})
      visit new_user_session_path
      fill_in "Username", with: user.name
      fill_in "Password", with: user.password
      click_button "Sign in"
      if opts[:fail]
        expect(page).to have_content 'Invalid username or password'
      else
        expect(page).to have_content "Signed in as #{user.name}"
      end
    end
  end

  module Request
    def login(user, opts = {})
      post user_session_path, user: { name: user.name, password: user.password }
    end
  end
end
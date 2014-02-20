class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_filter :authenticate_user!
  PROVIDERS = [:open_id, :facebook]
  protect_from_forgery :except => PROVIDERS

  def all
    @user, @auth = User.find_for_omniauth(request.env['omniauth.auth'], current_user)

    if !@auth.persisted? && current_user
      # There's a user already logged in. That means this must be a request to add
      # an omniauth authentication method to that user. Do so.
      add_new_auth_to_current_user
    elsif current_user
      # There's a user logged in, and they've just authenticated with an Authentication
      # we already know about. Handle that.
      handle_existing_auth_from_current_user @auth
    else
      # There is no user logged in, so this is a sign-up or sign-in attempt
      handle_omniauth_sign_up_or_in @user
    end
  end

  PROVIDERS.each { |method| alias_method method, :all }

protected

  def after_omniauth_failure_path_for(scope)
    request.env['HTTP_REFERER'] || new_user_registration_path
  end

private

  # Create an Authentication object from omniauth request data, and add it to the
  # logged-in user.
  def add_new_auth_to_current_user
    auth = Authentication.build_from_data(request.env['omniauth.auth'], request.env['omniauth.params'])
    auth.user = current_user
    if auth.save
      set_flash_message :notice, :success, :kind => kind
    else
      set_flash_message :alert, :failure, :kind => kind, :reason => failure_message
    end

    redirect_to edit_user_registration_url
  end

  # Process a logged-in user attempting to add an authentication which we actually
  # already know about.
  def handle_existing_auth_from_current_user(auth)
    if auth.user == current_user
      # The current user just authenticated from a remote service which is
      # already associated with their account. Tell them.
      set_flash_message :alert, :preexisting, :kind => kind
    else
      # The current user just authenticated from a remote service which is
      # already associated with *another* account. Show them the error.
      set_flash_message :error, :wrong_owner, :kind => kind
    end

    redirect_to edit_user_registration_url
  end

  # Process an omniauth success when no user is logged in. The user parameter is
  # either an existing user we can sign in, or a freshly-built user we can try to create
  def handle_omniauth_sign_up_or_in(user)
    if user.persisted?
      # The authentication matched a registered user. Sign them in.
      sign_in_and_redirect user, :event => :authentication
      set_flash_message :notice, :success, :kind => kind
    else
      # The authentication didn't match a registered user. Start sign-up processing
      session['devise.omniauth_data'] = request.env['omniauth.auth'].except('extra')
      session['devise.omniauth_params'] = request.env['omniauth.params']
      set_flash_message :notice, :incomplete, :kind => kind
      flash[:suppress_error_box] = true
      redirect_to new_user_registration_url
    end
  end

private
  def kind
    params[:action].titleize
  end
end
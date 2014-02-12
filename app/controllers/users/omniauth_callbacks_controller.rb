class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_filter :authenticate_user!
  protect_from_forgery :except => [:open_id]

  def all
    @user, @auth = User.find_for_omniauth(request.env['omniauth.auth'], current_user)

    if !@auth.persisted? && current_user
      # There's a user already logged in. That means this must be a request to add
      # an omniauth authentication method to that user. Do so.
      auth = Authentication.build_from_data(request.env['omniauth.auth'], request.env['omniauth.params'])
      auth.user = current_user
      if auth.save
        set_flash_message :notice, :success, :kind => 'OpenID'
      else
        set_flash_message :alert, :failure, :kind => 'OpenID', :reason => failure_message
      end

      redirect_to edit_user_registration_url
    elsif current_user && @auth.user == current_user
      # There's a user logged in, and they've just authenticated from a remote service which is
      # already associated with their account. Tell them, and redisplay the edit page
      set_flash_message :alert, :preexisting, :kind => 'OpenID'
      redirect_to edit_user_registration_url
    elsif current_user
      # There's a user logged in, and they've just authenticated from a remote service which is
      # already associated with *another* account. Show them the error, and redisplay the
      # edit page.
      set_flash_message :error, :wrong_owner, :kind => 'OpenID'
      redirect_to edit_user_registration_url
    else
      if @user.persisted?
        sign_in_and_redirect @user, :event => :authentication
        set_flash_message :notice, :success, :kind => 'OpenID'
      else
        session['devise.omniauth_data'] = request.env['omniauth.auth'].except('extra')
        session['devise.omniauth_params'] = request.env['omniauth.params']
        set_flash_message :notice, :incomplete, :kind => 'OpenID'
        flash[:suppress_error_box] = true
        redirect_to new_user_registration_url
      end
    end
  end

  alias_method :open_id, :all

protected
  def after_omniauth_failure_path_for(scope)
    request.env['HTTP_REFERER'] || new_user_registration_path
  end
end
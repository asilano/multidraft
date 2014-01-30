class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def open_id
    @user = User.find_for_openid_auth request.env['omniauth.auth']

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication
      set_flash_message :notice, :success, :kind => 'OpenID'
    else
      session['devise.openid_data'] = request.env['omniauth.auth'].except('extra')
      set_flash_message :notice, :incomplete, :kind => 'OpenID'
      flash[:suppress_error_box] = true
      redirect_to new_user_registration_url
    end
  end

protected
  def after_omniauth_failure_path_for(scope)
    request.env['HTTP_REFERER'] || new_user_registration_path
  end
end
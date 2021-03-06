class Users::RegistrationsController < Devise::RegistrationsController

  def remove_authentication
    case result = current_user.remove_authentication(params)
    when :dont_own
      set_flash_message :alert, :auth_removal_dont_own
    when :last_auth
      set_flash_message :alert, :auth_removal_last_auth
    when Authentication
      set_flash_message :notice, :auth_removal_succeeded, nickname: result.nickname
      @removed_id = params[:id]
    else
      set_flash_message :alert, :auth_removal_failed
    end

    respond_to do |format|
      format.html { redirect_to edit_user_registration_path }
      format.js
    end
  end

protected

  # Override Devise's method so that the current password is not required
  # to update the user's attributes.
  #
  # This is technically a gigantic security hole, but use of OpenID makes it hard
  # to require reauthentication, and it's not as if multidraft is a mine of
  # important personal data.
  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  # Override Devise's method so that a successful edit redirects to the edit path
  def after_update_path_for(user)
    edit_user_registration_path
  end

private
  def permitted_params
    [:name, :email, :password, :password_confirmation, authentications_attributes: [:provider, :uid, :nickname]]
  end

  def sign_up_params
    params.require(resource_name).permit(permitted_params)
  end

  def account_update_params
    params.require(resource_name).permit(permitted_params + [:remove_password])
  end
end
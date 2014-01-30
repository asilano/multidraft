class Users::RegistrationsController < Devise::RegistrationsController

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

end
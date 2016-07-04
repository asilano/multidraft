module ControllerMacros
  module SpecMethods
    def login_user(user = nil)
      @request.env["devise.mapping"] = Devise.mappings[:user]
      user ||= FactoryGirl.create(:user)
      user.confirm # or set a confirmed_at inside the factory. Only necessary if you are using the "confirmable" module
      sign_in user
    end
  end
end
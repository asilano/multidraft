class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable,
         :omniauthable, :omniauth_providers => Authentication.auth_methods

  has_many :authentications, dependent: :destroy
  accepts_nested_attributes_for :authentications

  has_many :drafters, dependent: :destroy
  has_many :drafts, -> { uniq }, through: :drafters

  attr_accessor :remove_password
  normalize_attributes :name, :email

  validates :name, presence: true, uniqueness: { case_sensitive: false, allow_blank: true }
  validates :email, presence: { if: :email_required? },
                    format: { with: /\A[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\z/i, allow_blank: true },
                    uniqueness: { case_sensitive: false }
  validates :password, presence: true, confirmation: true, length: { minimum: 5 }, if: :password_required?

  before_save :auto_confirm_openid, :on => 'create'

  # Remove the indicated authentication method from this User, unless it's the
  # last authentication method and the user has no email and/or password set.
  def remove_authentication(params)
    # Check that the given authentication exists, and belongs to this user
    auth = authentications.find_by_id(params[:id])
    return :dont_own unless auth

    # Disallow removal of an authentication method if the user doesn't have
    # an email address or password.
    if authentications.count == 1 && (email.blank? || encrypted_password.blank?)
      return :last_auth
    end

    # Otherwise, all fine. Perform the removal
    if auth.destroy
      return auth
    else
      return :failure
    end
  end

  # Override Devise's lookup mechanism to be case-insensitive (for postgres)
  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    conditions.permit! if conditions.class.to_s == "ActionController::Parameters"
    if login = conditions.delete(:name)
      where(conditions).where("lower(name) = ?", login.downcase).first
    else
      where(conditions).first
    end
  end

  # Handle looking up a sign-up or -in attempt by an Omniauth provider
  def self.find_for_omniauth(auth, current_user)
    authentication = Authentication.where(:provider => auth.provider.to_s, :uid => auth.uid).first_or_initialize
    user = authentication.user || current_user || User.new

    return user, authentication
  end

  # Implement method called by devise used to build a new resource from session data
  def self.new_with_session(params, session)
    super.tap do |user|
      # Don't use the session data if a form's been submitted!
      if !params.has_key?('name') && data = session["devise.omniauth_data"]
        # Create and attach an Authentication from the omniauth data
        user.authentications << Authentication.build_from_data(data, session['devise.omniauth_params'])

        # Use the OpenId's extra information to pre-populate the user's details.
        user.setup_details_from_info(data['info']) if data['info']

        # Validate the user built from OpenID data, to provide helpful feedback
        user.valid?
      end
    end
  end

  # Override devise's method, to allow all fields (even passwords) to be updated
  # without confirming the existing password.
  #
  # This is technically a gigantic security hole, but use of OpenID makes it hard
  # to require reauthentication, and it's not as if multidraft is a mine of
  # important personal data.
  def update_without_password(params, *options)
    remove_password = params.delete(:remove_password)
    result = update_attributes(params, *options)

    # Handle the user asking to remove their password
    if remove_password
      self.encrypted_password = ""
      save!
    end

    clean_up_passwords
    result
  end

  def setup_details_from_info(info)
    self.email = info['email'] if email.blank?
    self.name = info['nickname'] if name.blank?

    # Attempt to create a username from the supplied real name,
    # making sure each portion is capitalised and all spaces are removed
    username = info['fullname'] || info['name']
    username ||= (info['first_name'] || '') + ' ' + (info['last_name'] || '')
    self.name = username.titleize.gsub(/\s/, '') if name.blank?
  end

protected
  # Need a password when a password (or its confirmation) is given,
  # or for a new account which isn't using OpenID
  def password_required?
    !password.blank? || !password_confirmation.blank? || (!persisted? && authentications.empty?)
  end

  # Need an email if the account isn't using OpenID
  def email_required?
    authentications.empty?
  end

  # Prevent an OpenID signup from requiring email confirmation
  def auto_confirm_openid
    skip_confirmation! unless email_required?
  end

  # Override Devise's method to refer to the correct email field
  def reconfirmation_required?
    self.class.reconfirmable && @reconfirmation_required && !self.unconfirmed_email.blank?
  end
end

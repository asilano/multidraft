class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable,
         :omniauthable, :omniauth_providers => [:open_id]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :provider, :uid
  attr_accessor :remove_password
  normalize_attributes :name, :email

  validates_presence_of :name
  validates_presence_of :email, :if => :email_required?
  validates_uniqueness_of :name, :email, :case_sensitive => false, :allow_blank => true
  validates_format_of :email, :with => /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i, :allow_blank => true

  validates_presence_of :password, :if => :password_required?
  validates_confirmation_of :password, :if => :password_required?
  validates_length_of :password, :minimum => 5, :allow_blank => true

  before_save :auto_confirm_openid, :on => 'create'

  # Supported OpenID providers
  OpenIDProviders = [
    {name: 'Google', css_class: 'google-icon',
      data: {
        open_id_url: 'https://www.google.com/accounts/o8/id'
      }
    },
    {name: 'Yahoo', css_class: 'yahoo-icon',
      data: {
        open_id_url: 'http://me.yahoo.com'
      }
    },
    {name: 'StackExchange', css_class: 'se-icon',
      data: {
        open_id_url: 'http://openid.stackexchange.com'
      }
    },
    {name: 'Steam', css_class: 'steam-icon',
      data: {
        open_id_url: 'http://steamcommunity.com/openid'
      }
    },
    {name: 'LiveJournal', css_class: 'lj-icon',
      data: {
        open_id_url: 'http://%{parameter}.livejournal.com',
        parameter: 'LiveJournal username',
        param_placeholder: 'LiveJournal username'
        }
    },
    {name: 'OpenID', css_class: 'openid-icon',
      data: {
        open_id_url: '%{parameter}',
        parameter: 'OpenID URL',
        param_id: 'openid_url',
        param_placeholder: 'OpenID URL'
        }
    }
  ]

  # Override Devise's lookup mechanism to be case-insensitive (for postgres)
  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:name)
      where(conditions).where("lower(name) = ?", login.downcase).first
    else
      where(conditions).first
    end
  end

  # Handle looking up a sign-up or -in attempt by OpenID
  def self.find_for_openid_auth(auth)
    user = where(auth.slice(:provider, :uid)).first_or_initialize
    if !user.persisted?
      user.provider = auth.provider
      user.uid = auth.uid
      user.email = auth.info.try(:email)
    end
    user
  end

  # Implement method called by devise used to build a new resource from session data
  def self.new_with_session(params, session)
    super.tap do |user|
      # Don't use the session data if a form's been submitted!
      if !params.has_key?('name') && data = session["devise.openid_data"]
        user.provider = data['provider'] if user.provider.blank?
        user.uid = data['uid'] if user.uid.blank?

        # Use the OpenId's extra information to pre-populate the user's details.
        if info = data['info']
          user.email = info['email'] if user.email.blank?
          user.name = info['nickname'] if user.name.blank?

          # Attempt to create a username from the supplied real name,
          # making sure each portion is capitalised and all spaces are removed
          name = info['fullname'] || info['name']
          name ||= (info['first_name'] || '') + ' ' + (info['last_name'] || '')
          user.name = name.titleize.gsub(/\s/, '') if user.name.blank?
        end

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


protected

  # Need a password when a password (or its confirmation) is given,
  # or for a new account which isn't using OpenID
  def password_required?
    !password.blank? || !password_confirmation.blank? || (!persisted? && (provider.blank? || uid.blank?))
  end

  # Need an email if the account isn't using OpenID
  def email_required?
    provider.blank? || uid.blank?
  end

  # Prevent an OpenID signup from requiring email confirmation
  def auto_confirm_openid
    skip_confirmation! if provider.present? && uid.present?
  end

  # Override Devise's method to refer to the correct email field
  def reconfirmation_required?
    self.class.reconfirmable && @reconfirmation_required && !self.unconfirmed_email.blank?
  end
end

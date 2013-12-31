class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name
  # attr_accessible :title, :body

  validates_presence_of :name
  validates_uniqueness_of :name, :email, :case_sensitive => false

  # Override Devise's lookup mechanism to be case-insensitive (for postgres)
  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where("lower(name) = ?", login.downcase).first
    else
      where(conditions).first
    end
  end
end

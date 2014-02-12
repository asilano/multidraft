class Authentication < ActiveRecord::Base
  belongs_to :user
  attr_accessible :nickname, :provider, :uid

  def self.build_from_data(data, omniauth_params)
    nickname = omniauth_params.andand['omniauth_nickname']
    nickname ||= omniauth_params.andand['openid_url']
    nickname ||= data.provider.to_s.titleize

    new(:provider => data.provider, :uid => data.uid, :nickname => nickname)
  end
end

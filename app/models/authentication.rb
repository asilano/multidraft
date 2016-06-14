class Authentication < ActiveRecord::Base
  belongs_to :user

  def self.auth_methods
    [:open_id, :facebook, :google_oauth2]
  end

  def self.build_from_data(data, omniauth_params)
    nickname = omniauth_params.andand['omniauth_nickname']
    nickname ||= omniauth_params.andand['openid_url']
    nickname ||= data.provider.to_s.titleize

    new(:provider => data.provider, :uid => data.uid, :nickname => nickname)
  end

  def self.providers
    Providers.flat_map do |provider, family|
      family.map { |e| e.merge(provider: provider) }
    end
  end

private
  # Supported providers
  Providers = {
    :facebook => [
      {name: 'Facebook', css_class: 'facebook-icon'}],
    :google_oauth2 => [
      {name: 'Google', css_class: 'google-icon'}],
    :open_id => [
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
          param_placeholder: 'OpenID URL',
          nickname_from_url: true
          }
      }
    ],
  }
end

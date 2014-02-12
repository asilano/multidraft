class MoveUserOmniauthToAuthentications < ActiveRecord::Migration
  def up
    User.find(:all) do |user|
      if user.provider.present?
        user.authentications.create! provider: user.provider, uid: user.uid, nickname: user.uid
      end
    end
  end

  def down
    User.all do |user|
      auth = user.authentications.first
      if auth
        user.provider = auth.provider
        user.uid = auth.uid
        user.save!
      end
    end
  end
end

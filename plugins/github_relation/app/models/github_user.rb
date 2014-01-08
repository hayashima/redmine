class GithubUser < ActiveRecord::Base
  attr_accessible :login

  belongs_to :user

  after_create :create_user

  def self.create_users(users)
    users.each do |user_from_github|
      next if GithubUser.exists?(login: user_from_github.login)

      GithubUser.create(login: user_from_github.login)
    end
  end

  def self.user_by_github_login(user_by_github)
    github_user = self.where(login: user_by_github.login).first_or_create
    github_user.user
  end

  private
  def create_user
    return if User.exists?(login: self.login)

    user = self.build_user
    user.login = self.login
    user.firstname = self.login
    user.lastname = self.login
    user.mail = "#{self.login}@piyo.hoge"
    user.save!
    self.save!
  end
end

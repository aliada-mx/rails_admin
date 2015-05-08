# -*- encoding : utf-8 -*-
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    # Default strategy for signing in a user, based on their email and password in the database.
    class Md5DatabaseAuthenticatable < Base

      def valid?
        params[:user] && params[:user][:password]
      end

      def authenticate!
        user = User.find_by_email(params[:user][:email])
        md5_hashed_password = Digest::MD5.hexdigest(params[:user][:password])
        
        if user && 
           user.md5_password &&
           params[:user][:password].present? && 
           user.md5_password == md5_hashed_password 

          user.password = params[:user][:password]
          user.md5_password = nil
          user.save!
          success!(user)
        end
      end
    end
  end
end

Warden::Strategies.add(:md5_database_authenticatable, Devise::Strategies::Md5DatabaseAuthenticatable)

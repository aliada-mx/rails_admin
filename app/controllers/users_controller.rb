class UsersController < ApplicationController
  layout 'one_column'
  load_and_authorize_resource
  before_filter :set_user

  def edit
  end

  def update
  end

  def next_services
  end

  def previous_services
    current_user
  end

  private
    def set_user
      @user = User.find(params[:user_id])
    end
end

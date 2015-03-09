class UsersController < ApplicationController
  layout 'one_column'
  load_and_authorize_resource
  before_filter :set_user

  def edit
  end

  def update
  end

  def next_services
    @services = @user.services.in_the_future.to_a
  end

  def previous_services
    @services = User.find(params[:user_id]).services.in_the_past
  end

  private
    def set_user
      @user = User.find(params[:user_id])
    end
end

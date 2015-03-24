class UsersController < ApplicationController
  layout 'one_column'
  load_and_authorize_resource
  before_filter :set_user

  def edit
  end

  def update
  end

  def next_services
    services = @user.services.not_canceled.in_the_future.to_a

    @services = services.select do |service|
      service.one_timer? && service.recurrence_id.nil? || service.recurrent?
    end
  end

  def previous_services
    @services = User.find(params[:user_id]).services.in_the_past.not_canceled
  end

  private
    def set_user
      @user = User.find(params[:user_id])
    end
end

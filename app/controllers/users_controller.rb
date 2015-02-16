class UsersController < ApplicationController
  layout 'one_column'
  load_and_authorize_resource

  def profile
  end

  def edit
  end

  def update
  end

  def next_services
  end

  def previous_services
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params[:user]
    end
end

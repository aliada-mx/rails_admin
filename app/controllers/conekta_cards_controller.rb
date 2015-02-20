class ConektaCardsController < ApplicationController
  before_filter :set_user

  def create
    ConektaCard.create_for_user!(@user, conekta_card_params[:conekta_temporary_token])

    render json: { status: :ok, sender: :conekta, messages: I18n.t('conekta.card_created_successfully')}
  end

  private
    def conekta_card_params
      params.permit(:conekta_temporary_token)
    end
     
    def set_user
      @user = User.find(params[:user_id])
    end
end

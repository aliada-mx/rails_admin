# -*- encoding : utf-8 -*-
class ConektaCardsController < ApplicationController
  before_filter :set_user
  load_and_authorize_resource

  def update
    conekta_card = ConektaCard.create_for_user!(@user, conekta_card_params[:conekta_temporary_token], @user)

    render json: { status: :success, messages: I18n.t('conekta.card_created_successfully'), conekta_card_id: conekta_card.id }
  end

  private
    def conekta_card_params
      params.permit(:conekta_temporary_token)
    end
     
    def set_user
      @user = User.find(params[:user_id])
    end
end

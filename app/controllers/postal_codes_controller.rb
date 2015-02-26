class RecurrencesController < ApplicationController

  def show
    PostalCode.find_by_code(params[:code])
  end
end

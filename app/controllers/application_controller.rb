class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Exception raised by conekta
  rescue_from Conekta::Error do |exception|
    render json: { status: :error, sender: :conekta, messages: [exception.message_to_purchaser]}
  end
end

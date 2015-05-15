# -*- encoding : utf-8 -*-
class ActionDispatch::Routing::Mapper
  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
  end
end

Rails.application.routes.draw do
  # Admin
  mount RailsAdmin::Engine => 'aliadadmin', as: 'rails_admin'
  draw :rails_admin
  draw :static_pages
  draw :auth
  draw :initial_service
  draw :users
  draw :availability
  draw :aliada_webapp
  draw :utilities
  draw :paypal_ipn

  # Resque-web
  require "resque_web"
  ResqueWeb::Engine.eager_load!
  AliadaWebApp::Application.routes.draw do
    mount ResqueWeb::Engine => "/resque_web"
  end

end

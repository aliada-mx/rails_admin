Rails.application.routes.draw do
  get 'aliadadmin', to: redirect('aliadadmin/ticket')
  mount RailsAdmin::Engine => 'aliadadmin', as: 'rails_admin'

  root to: 'statics#home'
  get 'como-funciona', to: 'statics#how_it_works', as: :how_it_works
  get 'precios', to: 'statics#prices', as: :prices
  get 'faq', to: 'statics#faq', as: :faq
  get 'terminos', to: 'statics#terms', as: :terms
  get 'privacidad', to: 'statics#privacy', as: :privacy

  devise_for :users, path: '', path_names: {
    sign_in: :login,
    sign_out: :logout
  }

  resources :aliadas

  scope :servicio do
    post 'inicial', to: 'services#initial', as: :initial_service
    post 'create', to: 'services#create', as: :create_service
  end

  resource :users, path: 'perfil/:user_id' do
    get 'visitas-proximas', to: 'users#next_services', as: :next_services
    get 'historial', to: 'users#previous_services', as: :previous_services

    get 'servicio/nuevo', to: 'services#new', as: :new_service
    get 'servicio/:service_id', to: 'services#show', as: :show_service, service_id: /\d+/
  end

  devise_scope :aliadas do
    get 'aliadas/servicios/:token', to: 'aliadas#services', as: :servicios_aliadas
  end

  resources :schedules

  # Resque-web
  # TODO: protect with devise authentication
  #authenticate :admin do...
  require "resque_web"
  ResqueWeb::Engine.eager_load!
  AliadaWebApp::Application.routes.draw do
    mount ResqueWeb::Engine => "/resque_web"
  end
end

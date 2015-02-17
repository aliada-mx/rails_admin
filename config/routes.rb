Rails.application.routes.draw do
  get 'aliadadmin', to: redirect('aliadadmin/ticket')
  mount RailsAdmin::Engine => 'aliadadmin', as: 'rails_admin'

  root to: 'static_pages#home'
  get 'como-funciona', to: 'static_pages#how_it_works', as: :how_it_works
  get 'precios', to: 'static_pages#prices', as: :prices
  get 'faq', to: 'static_pages#faq', as: :faq
  get 'terminos', to: 'static_pages#terms', as: :terms
  get 'privacidad', to: 'static_pages#privacy', as: :privacy
  get 'patrones', to: 'static_pages#pattern_dictionary'

  devise_for :users, path: '', path_names: {
    sign_in: :login,
    sign_out: :logout
  }

  resources :aliadas

  scope :servicio do
    get 'inicial', to: 'services#initial', as: :initial_service
    post 'create', to: 'services#create', as: :create_service
  end

  resource :users, path: 'perfil/:user_id' do
    get 'visitas-proximas', to: 'users#next_services', as: :next_services
    get 'historial', to: 'users#previous_services', as: :previous_services

    get 'servicio/nuevo', to: 'services#new', as: :new_service
    get 'servicio/:service_id', to: 'services#show', as: :show_service, service_id: /\d+/
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

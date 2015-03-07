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

    post 'initial_feedback', to: 'services#initial_feedback', as: :initial_feedback
    post 'check_email', to: 'services#check_email', as: :check_email
    post 'check_postal_code', to: 'services#check_postal_code', as: :check_postal_code

    post 'create', to: 'services#create', as: :create_service
  end

  resource :users, path: 'perfil/:user_id', except: [:edit, :show] do
    get 'cuenta' => :edit, as: :edit

    get 'visitas-proximas', to: 'users#next_services', as: :next_services
    get 'historial', to: 'users#previous_services', as: :previous_services

    get 'servicio/nuevo', to: 'services#new', as: :new_service
    get 'servicio/:service_id', to: 'services#edit', as: :show_service, service_id: /\d+/

    post 'conekta_card/create', to: 'conekta_cards#create', as: :create_conekta_card
  end



  devise_scope :aliadas do
    get 'aliadas/servicios/:token', to: 'aliadas#services', as: :aliadas_services
    post 'aliadas/servicios/finish/:token', to: 'aliadas#finish', as: :finish_service
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

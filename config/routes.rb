# -*- encoding : utf-8 -*-
Rails.application.routes.draw do
  # Admin
  mount RailsAdmin::Engine => 'aliadadmin', as: 'rails_admin'
  scope :rails_admin do
    post 'add_billable_hours_to_service/:service_id', to: 'rails_admin_custom_actions#add_billable_hours_to_service', as: :add_billable_hours_to_service
  end

  # Static pages
  root to: 'static_pages#home'
  get 'como-funciona', to: 'static_pages#how_it_works', as: :how_it_works
  get 'precios', to: 'static_pages#prices', as: :prices
  get 'faq', to: 'static_pages#faq', as: :faq
  get 'terminos', to: 'static_pages#terms', as: :terms
  get 'privacidad', to: 'static_pages#privacy', as: :privacy
  get 'patrones', to: 'static_pages#pattern_dictionary'
  get 'jobs', to: 'static_pages#jobs', as: :jobs      
  get 'reclutamiento', to: 'static_pages#recruitment', as: :recruitment
  get 'reclutamiento/registro', to: 'static_pages#recruitment_signup', as: :recruitment_signup

  # Authentication and authorization
  devise_for :users, path: '', path_names: {
    sign_in: :login,
    sign_out: :logout
  }

  # Initial service
  scope :servicio do
    get 'inicial', to: 'services#initial', as: :initial_service

    post 'save_incomplete_service', to: 'services#incomplete_service', as: :save_incomplete_service
    post 'check_email', to: 'services#check_email', as: :check_email
    post 'check_postal_code', to: 'services#check_postal_code', as: :check_postal_code

    post 'create', to: 'services#create_initial', as: :create_initial_service
  end

  resource :users, path: 'perfil/:user_id', except: [:edit, :show] do

    # Main user sections
    get 'visitas-proximas', to: 'users#next_services', as: :next_services
    get 'historial', to: 'users#previous_services', as: :previous_services

    get 'cuenta' => :edit, as: :edit

    # Service
    match 'servicio/calificar/:service_id', to: 'scores#score_service', as: :score_service, via: [:get, :post]

    get 'servicio/nuevo', to: 'services#new', as: :new_service
    post 'servicio/create', to: 'services#create_new', as: :create_new_service

    get 'servicio/:service_id',   to: 'services#edit', as: :edit_service, service_id: /\d+/
    patch 'servicio/:service_id', to: 'services#update', as: :update_service, service_id: /\d+/
    post 'servicio/:service_id',  to: 'services#update', as: :update_service_post, service_id: /\d+/

    # Recurrence
    get 'recurrencias/:recurrence_id', to: 'recurrences#edit', as: :edit_recurrence, recurrence_id: /\d+/
    post 'recurrencias/:recurrence_id', to: 'recurrences#update', as: :update_recurrence, recurrence_id: /\d+/

    # Payments
    post 'conekta_card/create', to: 'conekta_cards#create', as: :create_conekta_card
    resources :conekta_cards, only: [ :show, :update ]

    post 'paypal/get_redirect_url', to: 'paypal_charges#get_redirect_url', as: :get_paypal_redirect_url
    get 'paypal/return', to: 'paypal_charges#paypal_return', as: :paypal_return

    # Admin only
    get 'visitas-canceladas', to: 'users#canceled_services', as: :canceled_services
    get 'recurrencias-desactivadas', to: 'recurrences#deactivated_recurrences', as: :deactivated_recurrences
  end

  # Convenience shortcut
  get 'mi-cuenta', to: 'users#user_account', as: :user_account_shortcut
  get 'historial', to: 'users#previous_services_shortcut', as: :previous_services_shortcut

  # Availability
  post 'aliadas-availability', to: 'aliadas_availability#for_calendar', as: :aliadas_availability

  # Aliada's webapp
  devise_scope :aliadas do
    get 'aliadas/servicios/:token', to: 'aliadas#services', as: :aliadas_services
    post 'aliadas/servicios/finish/:token', to: 'aliadas#finish', as: :finish_service
    post 'aliadas/servicios/confirm/:token', to: 'aliadas#confirm', as: :confirm_service
  end
  
  # Utilities
  get '#clear_session', to: 'user#clear_session', as: 'clear_session'

  # Paypal IPN
  post 'paypal_instant_payment_notification', to: 'paypal_charges#paypal_ipn', as: 'paypal_ipn'

  # Resque-web
  require "resque_web"
  ResqueWeb::Engine.eager_load!
  AliadaWebApp::Application.routes.draw do
    mount ResqueWeb::Engine => "/resque_web"
  end
end

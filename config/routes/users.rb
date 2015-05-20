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

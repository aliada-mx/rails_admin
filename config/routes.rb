Rails.application.routes.draw do
  root to: 'statics#home'
  get 'como-funciona', to: 'statics#how_it_works', as: :how_it_works
  get 'precios', to: 'statics#prices', as: :prices
  get 'faq', to: 'statics#faq', as: :faq
  get 'terminos', to: 'statics#terms', as: :terms
  get 'privacidad', to: 'statics#privacy', as: :privacy

  devise_for :users

  resources :aliadas

  scope :servicio do
    post 'inicial', to: 'services#initial', as: :initial_service
    post 'create', to: 'services#create', as: :create_service

    get 'nuevo', to: 'services#new', as: :new_service
    get ':service_id', to: 'services#show', as: :show_service, service_id: /\d+/
  end

  resource :user, path: 'perfil' do
    get 'visitas-proximas', to: 'users#next_services', as: :next_services
    get 'historial', to: 'users#previous_services', as: :previous_services
  end

  devise_scope :aliadas do
    get 'aliadas/servicios/:token', to: 'aliadas#services', as: :servicios_aliadas
  end

  resources :schedules
end

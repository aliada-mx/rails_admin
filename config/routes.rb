Rails.application.routes.draw do
  root 'static_pages#home'

  resources :aliadas
  resources :services
end

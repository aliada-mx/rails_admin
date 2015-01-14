Rails.application.routes.draw do
  resources :aliadas

  scope :servicios do
    post :nuevo, to: 'services#new', as: :new_service
    post :create, to: 'services#create', as: :create_service
    get '/:id', to: 'services#show', as: :show_service
  end

  resources :schedules
end

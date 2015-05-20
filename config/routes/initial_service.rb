# Initial service
scope :servicio do
  get 'inicial', to: 'services#initial', as: :initial_service

  post 'save_incomplete_service', to: 'services#incomplete_service', as: :save_incomplete_service
  post 'check_email', to: 'services#check_email', as: :check_email
  post 'check_postal_code', to: 'services#check_postal_code', as: :check_postal_code

  post 'create', to: 'services#create_initial', as: :create_initial_service
end

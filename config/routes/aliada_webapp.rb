# Aliada's webapp
devise_scope :aliadas do
  get 'aliadas/servicios/:token', to: 'aliadas#services', as: :aliadas_services
  post 'aliadas/servicios/finish/:token', to: 'aliadas#finish', as: :finish_service
  post 'aliadas/servicios/confirm/:token', to: 'aliadas#confirm', as: :confirm_service
end

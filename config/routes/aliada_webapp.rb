# Aliada's webapp
devise_scope :aliadas do
  get 'aliadas/servicios/:token', to: 'aliadas#next_services', as: :aliadas_services
  get 'aliadas/servicios-trabajados/:token', to: 'aliadas#worked_services', as: :aliadas_worked_services

  post 'aliadas/servicios/confirm/:token', to: 'aliadas#confirm', as: :confirm_service
  match 'aliadas/servicios/finish/:token', to: 'aliadas#finish', as: :finish_service, via: [:post, :patch]
  match 'aliadas/servicios/unassign/:token', to: 'aliadas#unassign', as: :unassign_service, via: [ :post, :get ]
  match 'aliadas/servicio/:token/:service_id', to: 'aliadas#edit_service_hours_worked', as: :edit_service_hours_worked, via: [ :post, :get ]
end

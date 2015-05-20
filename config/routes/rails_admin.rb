scope :rails_admin do
  post 'update_object_attribute/:object_class/:object_id', to: 'rails_admin_custom_actions#update_object_attribute', as: :update_object_attribute
  post 'add_billable_hours_to_service/:service_id', to: 'rails_admin_custom_actions#add_billable_hours_to_service', as: :add_billable_hours_to_service
  get 'aliada/get_schedule/:aliada_id/(/:init_date)', to: 'rails_admin_custom_actions#get_aliada_schedule', as: :get_aliada_schedule

end

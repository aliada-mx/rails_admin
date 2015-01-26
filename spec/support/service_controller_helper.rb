module TestingSupport
  module ServiceControllerHelper
    def fill_service_form(payment_method, service_type, starting_datetime, extra)
      fill_in 'service_billable_hours', with: '3'
      fill_in 'service_bathrooms', with: '1'
      fill_in 'service_bedrooms', with: '1'

      check "service_extra_ids_#{extra.id}"

      fill_in 'service_special_instructions', with: 'nada'
      fill_in 'service_address_attributes_street', with: 'Calle de las aliadas'
      fill_in 'service_address_attributes_number', with: '1' 
      fill_in 'service_address_attributes_interior_number', with: '2' 
      fill_in 'service_address_attributes_between_streets', with: 'Calle de los aliados, calle de los bifes' 
      fill_in 'service_address_attributes_colony', with: 'Roma' 
      fill_in 'service_address_attributes_state', with: 'DF' 
      fill_in 'service_address_attributes_city', with: 'Benito Juarez' 

      fill_in 'service_user_attributes_first_name', with: 'Guillermo' 
      fill_in 'service_user_attributes_last_name', with: 'Siliceo' 
      fill_in 'service_user_attributes_email', with: 'guillermo.siliceo@gmail.com' 
      fill_in 'service_user_attributes_phone', with: '5585519954' 

      choose "service_payment_method_id_#{payment_method.id}"
      choose "service_service_type_id_#{service_type.id}"

      fill_in 'service_date', with: starting_datetime.strftime('%Y-%m-%d')
      fill_in 'service_time', with: starting_datetime.strftime('%H:%M')
    end
  end
end

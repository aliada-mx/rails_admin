module TestingSupport
  module ServiceControllerHelper
    def fill_service_form(payment_method, service_type, starting_datetime, extra, zone)
      fill_hidden_input 'service_estimated_hours', with: 3
      fill_hidden_input 'service_bathrooms', with: '1'
      fill_hidden_input 'service_bedrooms', with: '1'

      check "service_extra_ids_#{extra.id}"

      fill_in 'service_special_instructions', with: 'nada'
      fill_in 'service_address_street', with: 'Calle de las aliadas'
      fill_in 'service_address_number', with: '1' 
      fill_in 'service_address_interior_number', with: '2' 
      fill_in 'service_address_between_streets', with: 'Calle de los aliados, calle de los bifes' 
      fill_in 'service_address_colony', with: 'Roma' 
      fill_in 'service_address_state', with: 'DF' 
      fill_in 'service_address_city', with: 'Benito Juarez' 
      fill_in 'service_address_postal_code_number', with: '11800'

      fill_in 'service_user_first_name', with: 'Guillermo' 
      fill_in 'service_user_last_name', with: 'Siliceo' 
      fill_in 'service_user_email', with: 'guillermo.siliceo@gmail.com' 
      fill_in 'service_user_phone', with: '5585519954' 

      choose "service_payment_method_id_#{payment_method.id}"
      choose "service_service_type_id_#{service_type.id}"

      fill_hidden_input 'service_date', with: starting_datetime.strftime('%Y-%m-%d')
      fill_hidden_input 'service_time', with: starting_datetime.strftime('%H:%M')
    end
  end
end

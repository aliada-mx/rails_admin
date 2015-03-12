module TestingSupport
  module ServiceControllerHelper
    def fill_new_service_form(service_type, starting_datetime, extra, zone)
      fill_service_fields(service_type, starting_datetime, extra, zone)
    end

    def fill_initial_service_form(payment_method, service_type, starting_datetime, extra, zone)
      fill_user_fields

      fill_address_fields

      fill_service_fields(service_type, starting_datetime, extra, zone)

      choose "service_payment_method_id_#{payment_method.id}"
      choose "service_service_type_id_#{service_type.id}"
    end

    def fill_service_fields(service_type, starting_datetime, extra, zone)
      fill_hidden_input 'service_estimated_hours', with: 3
      fill_hidden_input 'service_bathrooms', with: '1'
      fill_hidden_input 'service_bedrooms', with: '1'

      check "service_extra_ids_#{extra.id}"

      choose 'at_home'
      fill_in 'service_special_instructions', with: 'Algo especial'
      fill_in 'service_garbage_instructions', with: 'Algo de basura'
      fill_in 'service_attention_instructions', with: 'al perrito'
      fill_in 'service_equipment_instructions', with: 'con pinol mis platos'
      fill_in 'service_forbidden_instructions', with: 'no tocar mi colección de amiibos'

      fill_hidden_input 'service_date', with: starting_datetime.strftime('%Y-%m-%d')
      fill_hidden_input 'service_time', with: starting_datetime.strftime('%H:%M')

    end

    def fill_user_fields
      fill_in 'service_user_first_name', with: 'Guillermo' 
      fill_in 'service_user_last_name', with: 'Siliceo' 
      fill_in 'service_user_email', with: 'guillermo.siliceo@gmail.com' 
      fill_in 'service_user_phone', with: '5585519954' 
    end

    def fill_address_fields
      fill_in 'service_address_street', with: 'Calle de las aliadas'
      fill_in 'service_address_number', with: '1' 
      fill_in 'service_address_interior_number', with: '2' 
      fill_in 'service_address_between_streets', with: 'Calle de los aliados, calle de los bifes' 
      fill_in 'service_address_colony', with: 'Roma' 
      fill_in 'service_address_state', with: 'DF' 
      fill_in 'service_address_city', with: 'Benito Juarez' 
      fill_in 'service_address_postal_code_number', with: '11800'
    end
  
    def expect_to_have_a_complete_service(service)
      expect(service.zone_id).to eql zone.id
      expect(service.estimated_hours).to eql 3
      expect(service.bathrooms).to eql 1
      expect(service.bedrooms).to eql 1

      expect(service.special_instructions).to eql 'Algo especial'
      expect(service.garbage_instructions).to eql 'Algo de basura'
      expect(service.attention_instructions).to eql 'al perrito'
      expect(service.equipment_instructions).to eql 'con pinol mis platos'
      expect(service.forbidden_instructions).to eql 'no tocar mi colección de amiibos'
      expect(service.entrance_instructions).to eql true
    end

    def expect_to_have_a_complete_address(address)
      expect(address.postal_code.number).to eql '11800'
      expect(address.street).to eql 'Calle de las aliadas'
      expect(address.number).to eql "1"
      expect(address.interior_number).to eql "2"
      expect(address.between_streets).to eql 'Calle de los aliados, calle de los bifes'
      expect(address.colony).to eql 'Roma'
      expect(address.state).to eql 'DF'
      expect(address.city).to eql 'Benito Juarez'
    end

    def expect_to_have_a_complete_user(user)
      expect(user.first_name).to eql 'Guillermo'
      expect(user.last_name).to eql 'Siliceo'
      expect(user.email).to eql 'guillermo.siliceo@gmail.com'
      expect(user.phone).to eql '5585519954'
    end
  end
end

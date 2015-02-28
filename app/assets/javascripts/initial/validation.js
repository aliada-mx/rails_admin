aliada.services.initial.validate_form = function(form){
  $(form).validate({
    rules: {
          'service[user_attributes][email]': {
              required: true,
              email: true
          },
          'service[user_attributes][first_name]': {
              required: true
          },
          'service[user_attributes][last_name]': {
              required: true
          },
          'service[user_attributes][phone]': {
              required: true,
          },
          'service[address_attributes][street]': {
              required: true
          },
          'service[address_attributes][number]': {
              required: true
          },
          'service[address_attributes][colony]': {
              required: true
          },
          'service[address_attributes][between_streets]': {
              required: true
          },
          'service[address_attributes][city]': {
              required: true
          },
          'service[address_attributes][state]': {
              required: true
          },
          'service[address_attributes][postal_code]': {
              required: true
          },
      },
      messages: {
          'service[user_attributes][email]': {
              required: '¿Cuál es tu email?',
              email: 'Escribe un email válido'
          },
          'service[user_attributes][first_name]': {
              required: '¿Cuál es tu nombre?'
          },
          'service[user_attributes][last_name]': {
              required: '¿Cuales son tus apellidos?'
          },
          'service[user_attributes][phone]': {
              required: '¿Cuál es tu teléfono?'
          },
          'service[address_attributes][street]': {
              required: '¿En qué calle está tu domicilio?'
          },
          'service[address_attributes][number]': {
              required: '¿Cuál es el número de tu domicilio?'
          },
          'service[address_attributes][colony]': {
              required: '¿En qué colonia está tu domicilio?'
          },
          'service[address_attributes][between_streets]': {
              required: '¿Entre que calles está tu domicilio?'
          },
          'service[address_attributes][city]': {
              required: 'Ciudad o delegación del domicilio'
          },
          'service[address_attributes][state]': {
              required: 'Estado o distrito del domicilio'
          },
          'service[address_attributes][postal_code]': {
              required: '¿Cual es el código postal de tu domicilio?'
          },
      },
      errorPlacement: function(error, element) {
        $(element).attr('placeholder',error.text());
      },
      onfocusout: function(element) {
          $(element).valid();
      }
  });
}

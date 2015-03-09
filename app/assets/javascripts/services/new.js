//= require base
//
//= require jquery.calendario
//= require modules/calendar
//= require modules/dialogs
//
//= require services/new/_duration
//= require services/new/_personal_info
//= require services/new/_visit_info
//= require services/new/_payment

$(document).ready(function() {
  aliada.services.initial.$form = $('#new_service');
  create_initial_service_path = Routes.create_initial_service_path();

  // KNOCKOUT initialization
  aliada.ko = {
    invalid_form: ko.observable(false),
  };

  aliada.services.new.duration(aliada, ko);
  aliada.services.new.personal_info(aliada, ko);
  aliada.services.new.visit_info(aliada, ko);
  aliada.services.new.payment(aliada, ko);

  ko.validation.init({
    errorClass: 'error',
    decorateInputElement: true,
    insertMessages: false,
    errorsAsTitle: true,
  })

  // Activates knockout.js
  ko.applyBindings(aliada.ko);
  
  // When a user begins to type the validation error is gone
  aliada.services.initial.$form.find('input').on('click', function(){
    $(this).removeClass('error');
  })
});

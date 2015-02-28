//= require base
//= require initial/_step_1_duration
//= require initial/_step_2_personal_info
//= require initial/_step_3_visit_info
//= require initial/_step_4_payment
//= require initial/_step_5_success
//= require modules/dialogs

$(document).ready(function() {
  // KNOCKOUT initialization
  aliada.ko = {
    current_step: ko.observable(3),
  }

  aliada.services.initial.step_1_duration(aliada, ko);
  aliada.services.initial.step_2_personal_info(aliada, ko);
  aliada.services.initial.step_3_visit_info(aliada, ko);
  aliada.services.initial.step_4_payment(aliada, ko);
  aliada.services.initial.step_5_success(aliada, ko);

  aliada.ko.next_button_text = ko.computed(function(){
    var current_step = aliada.ko.current_step();
    if (current_step == 5){
      return 'Terminar'
    }
    return current_step < 4 ? 'Siguiente' : 'Confirmar visita'
  });

  // Activates knockout.js
  ko.applyBindings(aliada.ko);

  // Handle previous step
  $('#next_button').on('click',function(e){
      e.preventDefault();

      // Next if we are not on the last step
      var current_step = aliada.ko.current_step();
      var next_step = current_step === 5 ? current_step : current_step+1;

      aliada.ko.current_step(next_step);
  });
  
  // Handle next step
  $('#previous_button').on('click',function(e){
      e.preventDefault();

      // Next if we are not on the last step
      var current_step = aliada.ko.current_step();
      var previous_step = current_step === 1 ? current_step : current_step-1;

      aliada.ko.current_step(previous_step);
  });

  // Update incomplete service
  var $form = $('#new_service');

  get_feedback = function(){
    $form.ajaxSubmit({
      url: Routes.initial_feedback_path(),
      success: function(response){
        if (response.status == 'error'){
          switch(response.code){
            case 'email_already_exists':
              aliada.dialogs.email_already_exists(aliada.ko.email());
              break;
            case 'postal_code_missing':
              aliada.dialogs.postal_code_missing(aliada.ko.postal_code());
              break;
          }
        }
      },
      error: function(){
        aliada.dialogs.platform_error();
      }
    })
  }

  $form.find('input, select').on('change', get_feedback)
});

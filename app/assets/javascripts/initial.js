//= require base
//
//= require jquery.calendario
//= require modules/calendar
//= require modules/dialogs
//= require jquery.autogrow-textarea
//
//= require initial/_step_1_duration
//= require initial/_step_2_personal_info
//= require initial/_step_3_visit_info
//= require initial/_step_4_payment
//= require initial/_step_5_success
//= require initial/_live_feedback

$(document).ready(function() {
  aliada.services.initial.form = $('#new_service');
  var $form = aliada.services.initial.form



  // KNOCKOUT initialization
  aliada.ko = {
    current_step: ko.observable(1),

    // Move to specific step
    go_to_step: function(step_number){
      if(aliada.ko.is_valid_step()){
        aliada.ko.current_step(step_number);
      }
    }
  };

  aliada.ko.is_valid_step = ko.computed(function(){
    // Register as a dependency
    // so it runs everytime a step changes
    aliada.ko.current_step();

    // Validate the whole viewmodel
    return ko.validatedObservable(aliada.ko).isValid();
  });

  aliada.services.initial.step_1_duration(aliada, ko);
  aliada.services.initial.step_2_personal_info(aliada, ko);
  aliada.services.initial.step_3_visit_info(aliada, ko);
  aliada.services.initial.step_4_payment(aliada, ko);
  aliada.services.initial.step_5_success(aliada, ko);

  aliada.ko.next_button_text = ko.computed(function(){
    switch(aliada.ko.current_step()){
      case 1:
        return 'Siguiente'
      case 2:
        return aliada.ko.is_valid_step() ? 'Siguiente' : 'Confirma tu dirección'
      case 3:
        return aliada.ko.is_valid_step() ? 'Siguiente' : 'Escoge día y hora'
      case 4:
        return 'Confirmar visita'
      case 5:
        return 'Ver servicio'
    }
  });

  ko.validation.init({
    errorClass: 'error',
    decorateInputElement: true,
    insertMessages: false,
    errorsAsTitle: true,
  })

  // Activates knockout punches
  ko.punches.enableAll();
  // Activates knockout.js
  ko.applyBindings(aliada.ko);
  
  // Handle next step
  $('#next_button').on('click',function(e){
      e.preventDefault();
      var current_step = aliada.ko.current_step();

      if(!aliada.ko.is_valid_step()){

        // Trigger validation to provide feedback
        switch(current_step ){
            case 2:
              _.each(aliada.step_2_required_fields, function(element){
                aliada.ko[element].valueHasMutated();
              });
              break;
            default:
              break;
        }
        return;
      };

      // On payment step
      if (current_step === 4){
        $(aliada.services.initial.form).submit();
        return;
      }

      // Next if we are not on the last step
      var next_step = current_step === 5 ? current_step : current_step + 1;

      aliada.ko.current_step(next_step);
  });

  // Broadcast the entered a step event
  aliada.ko.current_step.subscribe(function(new_step){
    $.event.trigger({type: 'entering_step_'+new_step});
  });

  // Broadcast the leaving a step event
  aliada.ko.current_step.subscribe(function(current_step){
    $.event.trigger({type: 'leaving_step_'+current_step});
  }, aliada.ko, "beforeChange");

  aliada.services.initial.live_feedback(aliada.services.initial.form)

  // When a user begins to type the validation error is gone
  aliada.services.initial.form.find('input').on('click', function(){
    $(this).removeClass('error');
  })
});

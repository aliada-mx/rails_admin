//= require base
//
//= require jquery.calendario
//= require modules/calendar
//= require modules/dialogs
//= require jquery.autogrow-textarea
//
//= require services/initial/_step_1_duration
//= require services/initial/_step_2_personal_info
//= require services/initial/_step_3_visit_info
//= require services/initial/_step_4_payment
//= require services/initial/_step_5_success
//= require services/initial/_live_feedback

$(document).ready(function() {
  aliada.services.initial.$form = $('#new_service');
  create_initial_service_path = Routes.create_initial_service_path();

  // KNOCKOUT initialization
  aliada.ko = {
    current_step: ko.observable(1),
    form_action: ko.observable(create_initial_service_path)
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
        if ( aliada.ko.is_valid_step()  ){
          return 'Siguiente'
        }else{
          string = 'Escoge'
          if(aliada.ko.date.is_default()){
            string += ' día';
          }else if(aliada.ko.time.is_default()){
            string += ' hora';
          }
          return string;
        }
      case 4:
        return 'Confirmar visita'
      case 5:
        return 'Guardar servicio'
    }
  });

  aliada.ko.are_fields_editable = function(fields){
    var current_step = aliada.ko.current_step();
    switch(fields){
      case 'hours':
        return current_step > 1 && current_step < 5;
      case "address":
        return aliada.ko.is_address_done() && current_step !== 2 && current_step < 5;
      case "name_email_phone":
        return aliada.ko.is_name_email_phone_done() && current_step !== 2 && current_step < 2;
      case "datetime":
        return aliada.ko.is_datetime_done() && current_step !== 3 && current_step < 5;
      default:
        return false;
    }
  }

  ko.validation.init({
    errorClass: 'error',
    decorateInputElement: true,
    insertMessages: false,
    errorsAsTitle: true,
  })

  // Activates knockout.js
  ko.applyBindings(aliada.ko);
  
  // Handle next step
  $('#next_button').on('click',function(e){
      e.preventDefault();
      var current_step = aliada.ko.current_step();

      // Invalid steps provide feedback
      if(!aliada.ko.is_valid_step()){
        if(current_step === 2){
          // Trigger validation to provide feedback
          _.each(aliada.step_2_required_fields, function(element){
            aliada.ko[element].valueHasMutated();
          });
        }
        return;
      };

      switch(current_step ){
        case 4:
          aliada.services.initial.$form.submit();
          return;
        case 5:
          aliada.services.initial.$form.submit();
          return;
        default:
          break;
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

  aliada.services.initial.live_feedback(aliada.services.initial.$form)

  // When a user begins to type the validation error is gone
  aliada.services.initial.$form.find('input').on('click', function(){
    $(this).removeClass('error');
  })
});

//= require base
//
//= require jquery.calendario
//= require modules/calendar
//= require modules/dialogs
//
//= require initial/_step_1_duration
//= require initial/_step_2_personal_info
//= require initial/_step_3_visit_info
//= require initial/_step_4_payment
//= require initial/_step_5_success
//= require initial/live_feedback

$(document).ready(function() {
  aliada.services.initial.form = $('#new_service');

  aliada.services.initial.is_valid_step = function(){
    // Trigger update on to force validation feedback
    _.each(aliada.step_2_required_fields, function(element){
      aliada.ko[element].valueHasMutated();
    });

    return ko.validatedObservable(aliada.ko).isValid();
  };

  // Move to specific step
  aliada.move_to_step = function(){

    if(aliada.services.initial.is_valid_step()){
      var step_number = this;

      aliada.ko.current_step(step_number);
    }
  }


  // KNOCKOUT initialization
  aliada.ko = {
    current_step: ko.observable(2),
  };

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

  ko.validation.init({
    errorClass: 'error',
    decorateInputElement: true,
    insertMessages: false,
    errorsAsTitle: true,
  })

  // Activates knockout.js
  ko.applyBindings(aliada.ko);
  
  // Handle previous step
  $('#next_button').on('click',function(e){
      e.preventDefault();

      if(!aliada.services.initial.is_valid_step()){
        return;
      };

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


  // Entered a step event
  aliada.ko.current_step.subscribe(function(new_step){
    $.event.trigger({type: 'entered_step_'+new_step});
  });

  // Leaving a step event
  aliada.ko.current_step.subscribe(function(current_step){
    $.event.trigger({type: 'leaving_step_'+current_step});
  }, aliada.ko, "beforeChange");

  aliada.services.initial.live_feedback(aliada.services.initial.form);
});

//= require base
//
//= require jquery.calendario
//= require jquery.hc-sticky.min
//
//= require modules/calendar
//= require modules/dialogs
//
//= require services/edit/_duration
//= require services/edit/_datetime_selection
//= require services/edit/_form_submission

$(document).ready(function() {
  aliada.services.edit.$form = $('#new_service');

  // KNOCKOUT initialization
  aliada.ko = {
    current_step: ko.observable(1),
    service_id: ko.observable('')
  };

  aliada.services.edit.duration(aliada, ko);
  aliada.services.edit.datetime_selection(aliada, ko);

  ko.validation.init({
    errorClass: 'error',
    decorateInputElement: true,
    insertMessages: false,
    errorsAsTitle: true,
  })

  // Activates knockout.js
  ko.applyBindings(aliada.ko);
  
  // Smooth scroll for a href='#id'
  initialize_scroll_anchors();

  // Summary follows the scroll
  if(!isMobile.any){
    $('aside').hcSticky({stickTo: $('main'), top: '20'});
  }

  aliada.services.edit.bind_form_submission(aliada.services.edit.$form);

  aliada.services.edit.initialize_calendar_times();

});

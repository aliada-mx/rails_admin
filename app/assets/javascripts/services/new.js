//= require base
//
//= require jquery.calendario
//= require jquery.hc-sticky.min
//
//= require modules/calendar
//= require modules/dialogs
//
//= require services/new/_duration
//= require services/new/_datetime_selection

$(document).ready(function() {
  aliada.services.initial.$form = $('#new_service');
  create_initial_service_path = Routes.create_initial_service_path();

  // KNOCKOUT initialization
  aliada.ko = {
    invalid_form: ko.observable(false),
  };

  aliada.services.new.duration(aliada, ko);
  aliada.services.new.datetime_selection(aliada, ko);

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

  aliada.services.initial.initialize_calendar_times();

});

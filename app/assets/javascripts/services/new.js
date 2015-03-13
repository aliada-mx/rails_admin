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
//= require services/new/_form_submission

$(document).ready(function() {
  aliada.services.new.$form = $('#new_service');
  aliada.services.new.form_action = Routes.create_new_service_users_path(aliada.user.id);

  // KNOCKOUT initialization
  aliada.ko = {
    current_step: ko.observable(1),
    service_id: ko.observable('')
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

  aliada.services.new.bind_form_submission(aliada.services.new.$form);

  aliada.services.new.initialize_calendar_times();

});

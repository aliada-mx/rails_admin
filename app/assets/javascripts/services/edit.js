//= require base
//
//= require jquery.calendario
//= require jquery.hc-sticky.min
//= require jquery.pulsate.min
//= require URI.min
//
//= require modules/calendar
//= require modules/dialogs
//= require jquery.autogrow-textarea
//= require modules/open_cancel_dialog_on_page_load
//
//= require services/edit/_duration
//= require services/edit/_datetime_selection
//= require services/edit/_form_submission
$(document).ready(function() {

  aliada.services.edit.$form = $('#edit_service_form');

  // KNOCKOUT initialization
  aliada.ko = {
    current_step: ko.observable(1),
    service_id: ko.observable(''),
  };

  aliada.services.edit.duration(aliada, ko);
  aliada.services.edit.datetime_selection(aliada, ko);

  aliada.open_cancel_dialog_on_page_load();

  // Unhilight when a time is chosen
  aliada.ko.time.subscribe(function(new_time) {
    if (!aliada.ko.time.is_default()) {
      unhighlight('#choose-time');
    }
      mixpanel.track("MS-New Datetime Selected", {
	  "hour": aliada.ko.time(),
	  "day": aliada.ko.date(),
	  "service_id": aliada.ko.service_id()
      });
  });
    
    
  // Unhilight when a date is chosen
  aliada.ko.date.subscribe(function() {
    if (!aliada.ko.date.is_default()) {
      unhighlight('#choose-date');
    }
  });

  // Activates knockout.js
  ko.applyBindings(aliada.ko);

  // Smooth scroll for a href='#id'
  initialize_scroll_anchors();

  // Summary follows the scroll
  if (!isMobile.any) {
    $('aside').hcSticky({
      stickTo: $('main'),
      top: '20'
    });
  }

  aliada.services.edit.bind_form_submission(aliada.services.edit.$form);

  // Load original state
  aliada.ko.bedrooms(aliada.service.bedrooms);
  aliada.ko.bedrooms(aliada.service.bathrooms);

  // Update calendar on hour change
  aliada.ko.hours.subscribe(function(hours) {
    update_calendar();
  });

  // Update calendar on Aliadas change and update aliada_id
  $('#service_aliada_id').on('change', function() {
    aliada.service.aliada_id = $(this).find(':selected').val();
      mixpanel.track("MS-Aliada Changed", {
      "aliada_id": aliada.service.aliada_id
    });
    update_calendar();
  });

  aliada.ko.current_step.subscribe(function(step) {
    if (step == 2) {
      $('textarea').css('overflow', 'hidden').autogrow();
    }
  });

});

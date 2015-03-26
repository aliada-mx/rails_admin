//= require base
//
//= require jquery.calendario
//= require jquery.hc-sticky.min
//= require jquery.pulsate.min
//
//= require modules/calendar
//= require modules/dialogs
//= require jquery.autogrow-textarea
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

  // Unhilight when a time is chosen
  aliada.ko.time.subscribe(function() {
    if (!aliada.ko.time.is_default()) {
      unhighlight('#choose-time');
    }
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
  // Hours selector
  var service_type_selector = $("#service_estimated_hours").data("selectBox-selectBoxIt");
  service_type_selector.selectOption(aliada.service.hours_without_extras);

  // Update calendar on service type change
  $('.service_types.radio_buttons').on('change', function(e) {
    update_calendar();
  });

  // Update calendar on hour change
  aliada.ko.hours.subscribe(function(hours) {
    update_calendar();
  });

  // Update calendar on Aliadas change and update aliada_id
  $('#service_aliada_id').on('change', function() {
    aliada.service.aliada_id = $(this).find(':selected').val();

    update_calendar();
  });


aliada.ko.current_step.subscribe(function(step){
  if (step == 2){
    $('textarea').css('overflow', 'hidden').autogrow();
  }
});

});

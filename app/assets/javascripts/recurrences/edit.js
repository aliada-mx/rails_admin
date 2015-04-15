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
//= require recurrences/edit/_duration
//= require recurrences/edit/_datetime_selection
//= require recurrences/edit/_form_submission
$(document).ready(function() {

  aliada.recurrence.edit.$form = $('#edit_service_form');

  // KNOCKOUT initialization
  aliada.ko = {
    current_step: ko.observable(1),
    service_id: ko.observable(''),
  };

  aliada.recurrence.edit.duration(aliada, ko);
  aliada.recurrence.edit.datetime_selection(aliada, ko);

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

  aliada.recurrence.edit.bind_form_submission(aliada.recurrence.edit.$form);

  // Load original state
  aliada.ko.bedrooms(aliada.service.bedrooms);
  aliada.ko.bedrooms(aliada.service.bathrooms);
  // Hours selector
  var recurrence_rooms_selector = $("#recurrence_rooms_hours").data("selectBox-selectBoxIt");
  recurrence_rooms_selector.selectOption(aliada.service.hours_without_extras);

  // Update calendar on hour change
  aliada.ko.hours.subscribe(function(hours) {
    update_calendar();
  });

  // Update calendar on Aliadas change and update aliada_id
  $('#recurrence_aliada_id').on('change', function() {
    aliada.recurrence.aliada_id = $(this).find(':selected').val();

    update_calendar();
  });

  aliada.ko.current_step.subscribe(function(step) {
    if (step == 2) {
      $('textarea').css('overflow', 'hidden').autogrow();
    }
  });

});

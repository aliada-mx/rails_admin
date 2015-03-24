//= require base
//
//= require jquery.calendario
//= require jquery.hc-sticky.min
//= require jquery.pulsate.min
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
  if (!isMobile.any) {
    $('aside').hcSticky({
      stickTo: $('main'),
      top: '20'
    });

  // Update calendar on service type change
  $('.service_types.radio_buttons').on('change', function(e) {
    e.preventDefault();
    update_calendar();
  });

  aliada.ko.hours.subscribe(function(hours) {
    update_calendar();

  });

    aliada.services.new.bind_form_submission(aliada.services.new.$form);
  };

  // Update calendar on Aliadas change
  var $aliadas_selector = $('#service_aliada_id');

  // Aliadas selector updates aliada_id and calendar
  $aliadas_selector.on('change', function() {
    var $selected = $(this).find(':selected');

    aliada.service.aliada_id = $selected.val();
    update_calendar();

    highlight('#choose-date');
  });
});

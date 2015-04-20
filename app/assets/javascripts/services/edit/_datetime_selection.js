//= require services/edit/_calendar

aliada.services.edit.datetime_selection = function(aliada, ko) {
  // Select default service type from the form
  _(aliada.ko).extend({
    friendly_datetime: ko.observable('').extend({
      default_value: null
    }),
    dates: ko.observableArray([]),
    date: ko.observable('').extend({
      default_value: null
    }),

    times: ko.observableArray([]).extend({
      default_value: []
    }),
    time: ko.observable('').extend({
      default_value: null
    }),
  });

  aliada.ko.service_type_display_name = ko.computed(function() {
    return aliada.service.service_type.display_name;
  });

  aliada.ko.hours = ko.computed(function() {
    var hours = 1.5; // Starting with 1 room and 1 bathroom
    var extras_hours = aliada.ko.extras_hours();
    hours += extras_hours

    if (_.isNull(aliada.ko.forced_hours())) {
      var bathrooms_hours = (aliada.bathrooms_multiplier * aliada.ko.bathrooms());
      var bedrooms_hours = (aliada.bedrooms_multiplier * aliada.ko.bedrooms());
      hours += bathrooms_hours + bedrooms_hours;
    } else {
      return aliada.ko.forced_hours() + extras_hours;
    }
    return hours > aliada.minimum_hours_service ? hours : aliada.minimum_hours_service
  });

  aliada.ko.price = ko.computed(function() {
    return Math.ceil(aliada.ko.hours() * aliada.service.service_type.price_per_hour);
  });

  aliada.ko.is_datetime_done = ko.computed(function() {
    return !aliada.ko.date.is_default() && !aliada.ko.time.is_default();
  });

  // Calendar time logic Separated for structure purposes
  aliada.services.edit.initialize_calendar_times();

}

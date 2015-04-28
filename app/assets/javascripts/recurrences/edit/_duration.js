aliada.recurrence.edit.duration = function(aliada, ko) {

  _(aliada.ko).extend({
    bedrooms: ko.observable(aliada.recurrence.bedrooms),
    bathrooms: ko.observable(aliada.recurrence.bathrooms),
    forced_hours: ko.observable(null),
    extras_hours: ko.observable(0),
    cost_per_hour: ko.observable(aliada.cost_per_hour),
  });

  aliada.ko.bathrooms_text = ko.computed(function() {
    var sufix = aliada.ko.bathrooms() > 1 ? ' baños' : ' baño'
    return aliada.ko.bathrooms() + sufix
  });

  aliada.ko.bedrooms_text = ko.computed(function() {
    var sufix = aliada.ko.bedrooms() > 1 ? ' cuartos' : ' cuarto'
    return aliada.ko.bedrooms() + sufix
  });

  // Hours selector
  $('#recurrence_rooms_hours').on('change', function() {
    var $selected = $(this).find(':selected');
    var hours = $selected.val();
    aliada.ko.forced_hours(parseFloat(hours));

    // hide the alternative way of choosing hours
    $('.bathroom-bedrooms-container').slideUp();
  }).trigger('change'); // Trigger on load

  // Set hours depending on selected extras
  $('#extras').on('change', function() {
    var extras_hours = _.reduce($(this).find(':checked'), function(total, checkbox) {
      return total + parseFloat($(checkbox).data('hours'));
    }, 0)

    aliada.ko.extras_hours(extras_hours);
  }).trigger('change');
}
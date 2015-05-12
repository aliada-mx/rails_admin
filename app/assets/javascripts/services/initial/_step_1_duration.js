aliada.services.initial.step_1_duration = function(aliada, ko){

  _(aliada.ko).extend({
    bedrooms: ko.observable(1),
    bathrooms: ko.observable(1),
    forced_hours: ko.observable(null),
    extras_hours: ko.observable(0),
    extra_items: ko.observableArray([]),
    cost_per_hour: ko.observable(aliada.cost_per_hour),
  });

  aliada.ko.bathrooms_text = ko.computed(function(){
    var sufix = aliada.ko.bathrooms() > 1 ? ' baños' : ' baño'
    return aliada.ko.bathrooms()+sufix
  });

  aliada.ko.bedrooms_text = ko.computed(function(){
    var sufix = aliada.ko.bedrooms() > 1 ? ' cuartos' : ' cuarto'
    return aliada.ko.bedrooms()+sufix
  });


  aliada.ko.hours = ko.computed(function(){
      var hours = 1.5; // Starting with 1 room and 1 bathroom
      var extras_hours = aliada.ko.extras_hours();
      hours += extras_hours

      if (_.isNull(aliada.ko.forced_hours())){
        var bathrooms_hours = (aliada.bathrooms_multiplier * aliada.ko.bathrooms());
        var bedrooms_hours = (aliada.bedrooms_multiplier * aliada.ko.bedrooms());
        hours += bathrooms_hours + bedrooms_hours;
      }else{
        return aliada.ko.forced_hours() + extras_hours;
      }
      return hours > aliada.minimum_hours_service ? hours : aliada.minimum_hours_service});

  aliada.ko.price = ko.computed(function(){
    return Math.ceil(aliada.ko.hours() * aliada.ko.cost_per_hour());
  });


  // Hours selector
  $('#service_rooms_hours').on('change', function(){
    var $selected = $(this).find(':selected');
    var hours = $selected.val();
    aliada.ko.forced_hours(parseFloat(hours));
      
      mixpanel.track("IS-Service Hours Selected by Area", {
	  "hours": hours
      });

    // hide the alternative way of choosing hours
    $('.bathroom-bedrooms-container').slideUp();
  });

  // Set hours depending on selected extras
  $('#extras').on('change',function(e){
      var extras_hours = _.reduce($(this).find(':checked'), function(total, checkbox){
        return total + parseFloat($(checkbox).data('hours'));
      }, 0);

      var extra_items = _.map($(this).find(':checked'), function(checkbox){
        return "+" + $(checkbox).siblings('label').find('h4').text();
      });

      mixpanel.track("IS-Selected Items Changed", {
        "items": extra_items,
        "hours": extras_hours
      });

      aliada.ko.extra_items(extra_items);
      aliada.ko.extras_hours(extras_hours);
  });
}

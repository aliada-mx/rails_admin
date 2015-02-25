aliada.services.initial.step_1_duration = function(aliada, ko){
  aliada.ko.bathrooms_text = ko.computed(function(){
      var sufix = aliada.ko.bathrooms() > 1 ? ' baños' : ' baño'
    return aliada.ko.bathrooms()+sufix
  });

  aliada.ko.bedrooms_text = ko.computed(function(){
    var sufix = aliada.ko.bedrooms() > 1 ? ' cuartos' : ' cuarto'
    return aliada.ko.bedrooms()+sufix
  });

  aliada.ko.hours = ko.computed(function(){
      var hours = 0
      var extras_hours = aliada.ko.extras_hours();
      hours += extras_hours

      if (_.isNull(aliada.ko.forced_hours())){
        var bathrooms_hours = (aliada.bathrooms_multiplier * aliada.ko.bathrooms());
        var bedrooms_hours = (aliada.bedrooms_multiplier * aliada.ko.bedrooms());
        hours += bathrooms_hours + bedrooms_hours;
      }else{
        return aliada.ko.forced_hours() + extras_hours;
      }
      return hours > aliada.minimum_hours_service ? hours : aliada.minimum_hours_service
  });

  aliada.ko.price = ko.computed(function(){
      return Math.ceil(aliada.ko.hours() * aliada.cost_per_hour);
  });
    
  // Hours selector
  $('#service_estimated_hours').on('change', function(){
    var $selected = $(this).find(':selected');
    var hours = $selected.val();
    aliada.ko.forced_hours(parseFloat(hours));

    // hide the alternative way of choosing hours
    $('.bathroom-bedrooms-container').slideUp();
  });

  $('#extras').on('change',function(){
      var extras_hours = _.reduce($(this).find(':checked'), function(total, checkbox){
        return total + parseFloat($(checkbox).data('hours'));
      }, 0)

      aliada.ko.extras_hours(extras_hours);
  });
}

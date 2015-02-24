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
      if (!_.isNull(aliada.ko.forced_hours())){
        return aliada.ko.forced_hours();
      }
      var bathrooms_hours = (aliada.bathrooms_multiplier * aliada.ko.bathrooms());
      var bedrooms_hours = (aliada.bedrooms_multiplier * aliada.ko.bedrooms());
      var hours = bathrooms_hours + bedrooms_hours;
      return hours > aliada.minimum_hours_service ? hours : aliada.minimum_hours_service
  });

  aliada.ko.price = ko.computed(function(){
      return Math.ceil(aliada.ko.hours() * aliada.cost_per_hour);
  });
    
  $('#service_billable_hours').on('change', function(){
    var $selected = $(this).find(':selected');
    var hours = $selected.val();
    aliada.ko.forced_hours(hours);

    $('.counter-container').slideUp();
  });
}

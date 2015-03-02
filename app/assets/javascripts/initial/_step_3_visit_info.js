aliada.services.initial.step_3_visit_info = function(aliada, ko){
  _(aliada.ko).extend({
    date_hour: ko.observable('Fecha y hora de la visita'),
    times: ko.observableArray([{text:'9:00 AM', value: 99}, {text:'9:00 AM', value: 999}, {text:'9:00 AM', value: 9999}, {text:'9:00 AM', value: 99999}, {text:'9:00 AM', value: 999999}])
  });

  var calendar = aliada.initialize_calendar({}, function(){return true});

  // Update calendar when leaving first step so it has enough time to be ready when the user reaches the third
  $(document).on('leaving_step_1',function(){
      $.getJSON(Routes.aliada_availability)
  });

}

aliada.services.initial.step_3_visit_info = function(aliada, ko){

  _(aliada.ko).extend({
    date_hour: ko.observable('Fecha y hora de la visita'),
    times: ko.observableArray([{text:'9:00 AM', value: 99}, {text:'9:00 AM', value: 999}, {text:'9:00 AM', value: 9999}, {text:'9:00 AM', value: 99999}, {text:'9:00 AM', value: 999999}])
  });

}

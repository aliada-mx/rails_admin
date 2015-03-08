//= require initial/_calendar

aliada.services.initial.step_3_visit_info = function(aliada, ko){
    // Select default service type from the form
    var $selected_service_type = $('.service_types.radio_buttons').find(':checked');
    var default_service_type = $selected_service_type.parent('label').data('service-type');

    var on_step_3 = function(){ return aliada.ko.current_step() == 3 };

    _(aliada.ko).extend({
        date_hour: ko.observable('Fecha y hora de la visita'),
        dates: ko.observableArray([]),
        date: ko.observable('').extend({
          required: { onlyIf: on_step_3 }
        }),

        times: ko.observableArray([]),
        time: ko.observable('').extend({
          required: { onlyIf: on_step_3 }
        }),

        service_type: ko.observable(default_service_type),
    });

    aliada.ko.date_hour = ko.computed(function(){
      var date_hour = '';

      if(aliada.ko.date()){
        date_hour += aliada.ko.date();
      }
      if(aliada.ko.time()){
        date_hour += ' '
        date_hour += aliada.ko.time();
      }
    })

    aliada.ko.is_recurrent_service = ko.computed(function(){
        return aliada.ko.service_type().name == 'recurrent';
    });

    aliada.services.initial.initialize_calendar_times();
}

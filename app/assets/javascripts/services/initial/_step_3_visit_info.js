//= require services/initial/_calendar

aliada.services.initial.step_3_visit_info = function(aliada, ko){
    // Select default service type from the form
    var $selected_service_type = $('.service_types.radio_buttons').find(':checked');
    var default_service_type = $selected_service_type.parent('label').data('service-type');

    var on_step_3 = function(){ return aliada.ko.current_step() == 3 };

    _(aliada.ko).extend({
        friendly_datetime: ko.observable('').extend({
          default_value: 'Fecha y hora de la visita'
        }),
        dates: ko.observableArray([]),
        date: ko.observable('').extend({
          required: { onlyIf: on_step_3 },
          default_value: ''
        }),

        times: ko.observableArray([]).extend({
          default_value: []
        }),
        time: ko.observable('').extend({
          required: { onlyIf: on_step_3 },
          default_value: ''
        }),

        service_type: ko.observable(default_service_type),
    });

    aliada.ko.is_recurrent_service = ko.computed(function(){
      return aliada.ko.service_type().name == 'recurrent';
    });

    aliada.ko.is_datetime_done = ko.computed(function(){
      // Register for updates when this change:
      aliada.ko.friendly_datetime();

      return !aliada.ko.friendly_datetime.is_default();
    });

    // Calendar time logic Separated for structure purposes
    aliada.services.initial.initialize_calendar_times();
}

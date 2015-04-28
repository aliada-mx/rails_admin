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
      return Math.ceil(aliada.ko.hours() * aliada.ko.service_type().price_per_hour );
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
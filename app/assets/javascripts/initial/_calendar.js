aliada.services.initial.initialize_calendar_times = function(){
  function on_calendar_day_click($el, $content, times, dateProperties){
    aliada.ko.times(times || []);

    aliada.ko.date(dateProperties.strdate);

    // Broadcast the change so it gets saves to the incomplete service
    aliada.services.initial.$form.trigger('change');

    // Only interact with available dates
    if( !$el.hasClass('fc-content') ){
      return;
    }

    //Remove previous selected
    $('.fc-selected-day').removeClass("fc-selected-day");
    $('.fc-selected-recurrences').removeClass('fc-selected-recurrences');
    $('.fc-selected-recurrences-below').removeClass('fc-selected-recurrences-below');

    //Mark the current selected 
    $el.addClass("fc-selected-day");

    //Render recurrences
    if (aliada.ko.is_recurrent_service()) {

      //Get the day and day-of-the-week from the selected element
      dia = parseInt($el.children('span.fc-date').text());
      diaSemana = $el.children('span.fc-weekday').text();

      //Select days below the selected date and add class fc-selected-recurrencias
      $('div.fc-row div').filter(function(index, elemen) {
          diaEl = parseInt($(elemen).children('span.fc-date').text());
          diaSemanaEl = $(elemen).children('span.fc-weekday').text();

          return ((diaEl >= dia) && (diaSemanaEl === diaSemana));
        }).addClass('fc-selected-recurrences-below');
    }


    return false;
  };

  function update_calendar(){
    var hours = aliada.ko.hours();
    var service_type_id = aliada.ko.service_type().id;
    var postal_code_number = aliada.ko.postal_code_number();

    // Prevent further user interaction to avoid double requests
    aliada.calendar.lock(calendar);

    // Invalidate the step to force the user to choose
    aliada.ko.date('');
    aliada.ko.time('');

    // Get data from server
    aliada.calendar.get_dates_times(hours, service_type_id, postal_code_number).then(function(dates_times){
        // Update the calendar
        calendar.setData(dates_times);

        // Select first date of the calendar as a default
        var date = $calendar_container.find('.fc-content');
        // If no date is found empty
        if(date.length > 0){
          date.first().click();
        }else{
          aliada.ko.times([]);
          aliada.ko.time('');
        }

        aliada.calendar.un_lock(calendar);
      }).caught(function(error){
        aliada.dialogs.platform_error(error);
      })
    }

    var $calendar_container = $('#calendar');
    var calendar = aliada.calendar.initialize({container: $calendar_container,
        dates: aliada.ko.dates(), 
        on_day_click: on_calendar_day_click });

    // Update calendar when leaving second step so it has enough time to be ready 
    // becase thats when we have a postal code to search our availability
    $(document).on('leaving_step_2',function(){
      update_calendar();
    });

    // When the service type changes the dates available change so update the calendar
    $('.service_types.radio_buttons').on('change', function(e){
      e.preventDefault();
      update_calendar();
    });
};

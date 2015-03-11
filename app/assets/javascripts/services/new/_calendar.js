aliada.services.initial.initialize_calendar_times = function(){
  function on_calendar_day_click($el, $content, times, dateProperties){
    // Reload times
    aliada.ko.times(times || []);

    // Reset the time
    aliada.ko.time.default();

    // Set the date
    aliada.ko.date(dateProperties.strdate);

    // Broadcast the change so live_feedback can report it
    aliada.services.initial.$form.trigger('change');

    // Bail if there are no available hours
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
    var availability_options = {
      hours: aliada.ko.hours(),
      service_type_id: aliada.ko.service_type().id,
      postal_code_number: aliada.user.postal_code_number,
      aliada_id: aliada.user.aliada_id
    };

    // Prevent further user interaction to avoid double requests
    aliada.calendar.lock(calendar);

    // Invalidate to force the user to choose
    aliada.ko.date.default();
    aliada.ko.time.default();
    // Reset our summary
    aliada.ko.friendly_datetime.default();


    // Get data from server
    aliada.calendar.get_dates_times(availability_options)
    .then(function(dates_times){
        // Update the calendar
        calendar.setData(dates_times);

        // Force the user to select a date first
        aliada.ko.times.default();
        aliada.ko.time.default();

        aliada.calendar.un_lock(calendar);
      }).caught(function(error){
          aliada.dialogs.platform_error(error);
        })
    }

    var $calendar_container = $('#calendar');
    var calendar = aliada.calendar.initialize({container: $calendar_container,
        dates: aliada.ko.dates(), 
        on_day_click: on_calendar_day_click 
      });

    // Update calendar on choosing an aliada
    $('')

    // When the service type changes the dates available change so update the calendar
    $('.service_types.radio_buttons').on('change', function(e){
        e.preventDefault();
        update_calendar();
      });

    // Aliadas changing
    var $aliadas_selector = $('#aliadas_selector');
    aliada.user.aliada_id = $aliadas_selector.val()

    // selector update aliada_id
    $aliadas_selector.on('change', function(){
      var $selected = $(this).find(':selected');

      aliada.user.aliada_id = $selected.val();
        update_calendar();
    });
};

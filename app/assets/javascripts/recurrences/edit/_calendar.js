aliada.services.edit.initialize_calendar_times = function() {
  function on_calendar_day_click($el, $content, times, dateProperties) {
    // Bail if there are no available hours
    if (!$el.hasClass('fc-content')) {
      return;
    }

    // Reload times
    aliada.ko.times(times || []);
    aliada.ko.friendly_datetime(dateProperties.friendly_date);

    // Reset the time
    aliada.ko.time.reset();

    // Set the date
    aliada.ko.date(dateProperties.strdate);

    highlight('.time-button:first');

    //Remove previous selected
    $('.fc-selected-day').removeClass("fc-selected-day");
    $('.fc-selected-recurrences').removeClass('fc-selected-recurrences');
    $('.fc-selected-recurrences-below').removeClass('fc-selected-recurrences-below');

    //Mark the current selected 
    $el.addClass("fc-selected-day");


    //Get the day and day-of-the-week from the selected element
    dia = parseInt($el.children('span.fc-date').text());
    diaSemana = $el.children('span.fc-weekday').text();

    //Select days below the selected date and add class fc-selected-recurrencias
    $('div.fc-row div').filter(function(index, elemen) {
      diaEl = parseInt($(elemen).children('span.fc-date').text());
      diaSemanaEl = $(elemen).children('span.fc-weekday').text();

      return ((diaEl >= dia) && (diaSemanaEl === diaSemana));
    }).addClass('fc-selected-recurrences-below');


    return false;
  };

  function update_calendar(selected_date, selected_time) {
    return new Promise(function(resolve, reject) {
      var availability_options = {
        hours: aliada.ko.hours(),
        service_type_id: aliada.recurrence.service_type.id,
        postal_code_number: aliada.user.postal_code_number,
        aliada_id: aliada.ko.aliada_id(),
        user_id: aliada.user.id,
        recurrence_id: aliada.recurrence.id,
      };

      // Prevent further user interaction to avoid double requests
      aliada.calendar.lock(calendar);

      // Reset our summary
      aliada.ko.friendly_datetime.reset();

      // Get data from server
      aliada.calendar.get_dates_times(availability_options)
        .then(function(dates_times) {
          // Update the calendar
          calendar.setData(dates_times);

          // Force the user to select a date first
          aliada.ko.times.reset();
          aliada.ko.time.reset();

          aliada.calendar.un_lock(calendar);
          resolve(calendar);
        }).caught(function(error) {
          aliada.dialogs.platform_error(error);
          reject();
        })
    });
  };

  var $calendar_container = $('#calendar');
  var calendar = aliada.calendar.initialize({
    container: $calendar_container,
    dates: aliada.ko.dates(),
    on_day_click: on_calendar_day_click
  });

  _calendar = calendar;

  // Call local update_calendar on demand
  $(document).on('update-calendar', function() {
    highlight('#choose-date');
    update_calendar()
  })

  window.setTimeout(function(){
    // Update calendar on page load
    update_calendar().then(function(calendar) {
      updateMonthYear();
      calendar.chooseDay(aliada.service.day);

      aliada.ko.time(aliada.recurrence.time);
      aliada.ko.date(aliada.recurrence.date);
      aliada.ko.friendly_datetime(aliada.recurrence.friendly_datetime);
    });
  }, 0)

  function updateMonthYear() {
    var $month = $('#month').html(calendar.getMonthName()),
        $year = $('#year').html(calendar.getYear());

    $month.html(calendar.getMonthName());
    $year.html(calendar.getYear());
  };
};

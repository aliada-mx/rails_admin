aliada.initialize_calendar = function(dates, is_recurrent){

  function onDayClick($el, $content, dateProperties){
    //Erase the hours from the previously selected day
    $('#cal-hours').empty();

    //Mark the current day as selected and remove the previous one
    $('.fc-selected-day').removeClass("fc-selected-day");
    $el.addClass("fc-selected-day");

    //Convert from 1-1-2015 to 01-01-2015
    dateClicked = twoDigit(dateProperties.month) + "-" +
        twoDigit(dateProperties.day) + "-" +
        dateProperties.year;

    if (dates[dateClicked]) {
        //Render each hour of the selected date
        dates[dateClicked].forEach(function(h) {
            $('#cal-hours').append('<button>' + h + '</button>')
        });
    }

    //Pinta recurrencias
    if (is_recurrent()) {
        //Erase the class from the previous selection
        $('.fc-selected-recurrences').removeClass('fc-selected-recurrences');

        //Get the day and day-of-the-week from the selected element
        dia = parseInt($el.children('span.fc-date').text());
        diaSemana = $el.children('span.fc-weekday').text();

        //Select days below the selected date and add class fc-selected-recurrencias
        $('div.fc-row div').filter(function(index, elemen) {

            diaEl = parseInt($(elemen).children('span.fc-date').text());
            diaSemanaEl = $(elemen).children('span.fc-weekday').text();

            return ((diaEl >= dia) && (diaSemanaEl === diaSemana));

        }).addClass('fc-selected-recurrences');
    }

    return false;
  }

  var twoDigit = function(s) {
          s = s.toString();
          if (s.length == 1)
              return "0" + s;

          return s;
      }
      //Variable con las fechas y la disponibilidad de cada uno

  calendario = $('#calendar').calendario({
      caldata: dates,
      weekabbrs: ['DOM', 'LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB'],
      months: ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Augusto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'],
      displayMonthAbbr: false,
      displayWeekAbbr: true,
      onDayClick: onDayClick
  });

  //update Month and year
  var $month = $('#month').html(calendario.getMonthName()),
      $year = $('#year').html(calendario.getYear());

  function updateMonthYear() {
    $month.html(calendario.getMonthName());
    $year.html(calendario.getYear());
  };
  
  //Next month
  $('#next').on('click', function(e) {
      e.stopImmediatePropagation();
      calendario.gotoNextMonth(updateMonthYear);
  });
    
  //Previous month
  $('#prev').on('click', function(e) {
      e.stopImmediatePropagation();
      calendario.gotoPreviousMonth(updateMonthYear);
  });

  return calendario;
}

$(function(){
  var twoDigit = function(s) {
          s = s.toString();
          if (s.length == 1)
              return "0" + s;

          return s;
      }
      //Variable con las fechas y la disponibilidad de cada uno

  cal = $('#calendar').calendario({
      month: 1,
      year: 2015,
      caldata: aliada.dates,
      weekabbrs: ['DOM', 'LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB'],
      months: ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Augusto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'],

      displayMonthAbbr: false,

      displayWeekAbbr: true,

      onDayClick: function($el, $content, dateProperties) {
          //Erase the hours from the previously selected day
          $('#cal-hours').empty();

          //Mark the current day as selected and remove the previous one
          $('.fc-selected-day').removeClass("fc-selected-day");
          $el.addClass("fc-selected-day");

          //Convert from 1-1-2015 to 01-01-2015
          dateClicked = twoDigit(dateProperties.month) + "-" +
              twoDigit(dateProperties.day) + "-" +
              dateProperties.year;

          if (aliada.dates[dateClicked]) {
              //Render each hour of the selected date
              aliada.dates[dateClicked].forEach(function(h) {
                  $('#cal-hours').append('<button>' + h + '</button>')
              });
          }


          //Pinta recurrencias
          if (true) {
              //Erase the class from the previous selection
              $('.fc-selected-recurrencias').removeClass('fc-selected-recurrencias');

              //Get the day and day-of-the-week from the selected element
              dia = parseInt($el.children('span.fc-date').text());
              diaSemana = $el.children('span.fc-weekday').text();

              //Select days below the selected date and add class fc-selected-recurrencias
              $('div.fc-row div').filter(function(index, elemen) {

                  diaEl = parseInt($(elemen).children('span.fc-date').text());
                  diaSemanaEl = $(elemen).children('span.fc-weekday').text();

                  return ((diaEl >= dia) && (diaSemanaEl === diaSemana));

              }).addClass('fc-selected-recurrencias');
          }

          return false;
      }
  });

  //update Month and year
  $month = $('#custom-month').html(cal.getMonthName()),
      $year = $('#custom-year').html(cal.getYear());

  function updateMonthYear() {
          $month.html(cal.getMonthName());
          $year.html(cal.getYear());
      }
      //Event handlers
  $('#custom-next').on('click', function() {
      cal.gotoNextMonth(updateMonthYear);
  });
  $('#custom-prev').on('click', function() {
      cal.gotoPreviousMonth(updateMonthYear);
  });
})

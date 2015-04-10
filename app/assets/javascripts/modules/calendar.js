aliada.calendar.initialize = function(options){
  var dates = options.dates,
      container = options.container,
      on_day_click = options.on_day_click;

  var calendario = $(container).calendario({
      caldata: dates,
      weeks : [ 'Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado' ],
      weekabbrs: ['DOM', 'LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB'],
      months: ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Augusto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'],
      displayMonthAbbr: false,
      displayWeekAbbr: true,
      onDayClick: on_day_click
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

aliada.calendar.get_dates_times = function(availability_options){
  return new Promise(function(resolve,reject){
    $.ajax(Routes.aliadas_availability_path(), {
      method: 'POST',
      dataType: "json",
      beforeSend: add_csrf_token,
      data: availability_options,
    }).done(function(response){
      if(response.status == 'success'){
        resolve(response.dates_times);
      }else if (response.status == 'error'){
        reject(response);
      }
    }).fail(function(response){

      reject(response.responseText);

    })
  })
}

aliada.calendar.lock = function(calendar){
  $lock_overlay = calendar.$el.parents('.calendar-wrap').addClass('locked');
}

aliada.calendar.un_lock = function(calendar){
  $lock_overlay = calendar.$el.parents('.calendar-wrap').removeClass('locked');
}
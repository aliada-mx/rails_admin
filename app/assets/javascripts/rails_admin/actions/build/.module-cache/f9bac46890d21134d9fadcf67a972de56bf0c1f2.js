var state_chaged = 'Hola';
var SchedulesApp = React.createClass({displayName: "SchedulesApp",
  getInitialState: function () {
    return { schedules: this.props.schedules };
  },
  componentDidMount: function () {
    $.ajax({
      url: url_aliada, dataType: 'json'
    }).done( function( data ) {
      _.each( data, function( schedule ){
        var schedule_day = moment( schedule.datetime );
        var schedule_hours = parseFloat(schedule.estimated_hours).toFixed();
        var start_hour = 0, padding_hours = 0;
        for(; start_hour < schedule_hours ; start_hour++ ){
          schedule_day.add(start_hour, 'h');
          class_name = 's_' + schedule_day.format('MM_DD_') + schedule_day.format('ddd').toLowerCase() + '_' + schedule_day.format('HH');
          schedule_day = moment( schedule.datetime );
          if( schedule.service_type_id === 1){
            $('.'+class_name).find('.recurrent').addClass('active').html( schedule.user.full_name );
          }
          if( schedule.service_type_id === 2){
            $('.'+class_name).find('.one_time').addClass('active').html( schedule.user.full_name );
          }
        }
        start_hour = 0;
        padding_hours = parseFloat(schedule.hours_after_service).toFixed();
        for(; start_hour < padding_hours ; start_hour++ ){
          schedule_day.add( (parseInt(schedule_hours) + parseInt(start_hour)), 'h');
          class_name = 's_' + schedule_day.format('MM_DD_') + schedule_day.format('ddd').toLowerCase() + '_' + schedule_day.format('HH');
          schedule_day = moment( schedule.datetime );          
          $('.'+class_name).find('.padding').addClass('active').append('<p>schedule.user.full_name</p>');
        }
      });
    });
  },
  render: function() {
    var tableStyle = { width: '100%' };
    return ( 
      React.createElement("div", null, 
        React.createElement(SchedulesList, {slist: this.state.schedules})
      )
    );
  }
});

var SchedulesList = React.createClass({displayName: "SchedulesList",
  render: function() {
    var schedules = [];
    var tableStyle = { width: '100%' };
    var last_hour = 20;
    var current_hour = 7;
    var row_key = '';
    for(; current_hour <= last_hour; current_hour++){
      var hour = moment( current_hour, 'HH');
      var row_key = 'row_' + hour.format('HH');
      schedules.push( React.createElement(ScheduleRow, {key: row_key, hour: current_hour}) );
    }
    return ( 
      React.createElement("div", null, 
        React.createElement("table", {className: "table", style: tableStyle}, 
          React.createElement("thead", null, React.createElement("tr", null, React.createElement("th", null), React.createElement("th", null, "Domingo"), React.createElement("th", null, "Lunes"), React.createElement("th", null, "Martes"), React.createElement("th", null, "Miércoles"), React.createElement("th", null, "Jueves"), React.createElement("th", null, "Viernes"), React.createElement("th", null, "Sábado"))), 
          React.createElement("tbody", null, schedules)
        )
      )
    );
  }
});

var ScheduleRow = React.createClass({displayName: "ScheduleRow",
  render: function() {
    var week_table_array = ['hour', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']
    var that = this;

    var curr_day = new Date;
    var first_day = curr_day.getDate() - curr_day.getDay();
    var week_first_day = new Date( curr_day.setDate( first_day ) );
    var week_day = moment( week_first_day );

    return (
      React.createElement("tr", null, 
        
          week_table_array.map( function( day ) {
            var hour = moment( that.props.hour, 'HH');
            var class_name = '';
            var row_text = '';
            if( day !== 'hour' ){
              class_name = 's_' + week_day.format('MM_DD')+ '_' + day + '_' + hour.format('HH');
              week_day.add(1, 'd');
            } else {
              class_name = day + '_' + hour.format('HH');
              row_text = hour.format('HH:mm');
              week_day = moment( week_first_day );
            }
            return React.createElement(ScheduleCell, {key: class_name, text: row_text, class_name: class_name });
          })
        
      )
    );
  }
});

var ScheduleCell = React.createClass({displayName: "ScheduleCell",
  render: function() {
    return (React.createElement("td", {className: this.props.class_name}, 
      React.createElement("div", {className: "recurrent"}), 
      React.createElement("div", {className: "one_time"}), 
      React.createElement("div", {className: "padding"}), 
      React.createElement("div", {className: "text"}, this.props.text)));
  }
});
var fill_schedules =  function( schedules ){
    var curr_day = new Date;
    var first_day = curr_day.getDate() - curr_day.getDay();
    var last_day = first_day + 6;

    var week_first_day = new Date( curr_day.setDate( first_day ) );
    var week_last_day = new Date( curr_day.setDate( last_day ) );
    _.each( schedules, function( schedule ){
      var schedule_day = moment( schedule.datetime );

      var schedule_hours = parseFloat(schedule.estimated_hours);
      var schedule_padding_hours = parseFloat(schedule.hours_after_service);

      var schedule_time = moment( schedule.datetime ).add( schedule_hours.toFixed(), 'hour');
      var schedule_padding_time = moment( schedule.datetime ).add( ( parseInt(schedule_hours.toFixed()) + parseInt(schedule_padding_hours.toFixed()) ), 'hour');

      if( moment( active_day.format() ).isBetween( schedule_day.format(), schedule_time.format() ) ){
        row_text = schedule.id + ' - ' +schedule.user.full_name;
        service_type = schedule.service_type_id;
      }

      if( moment( active_day.format() ).isBetween( schedule_time.format(), schedule_padding_time.format() ) ){
        row_text = 'padding';
        service_type = 4;
      }

  });
};

React.render( React.createElement(SchedulesApp, null), document.getElementById( "SchedulesApp" ) );
var SchedulesApp = React.createClass({displayName: "SchedulesApp",
  getInitialState: function() {    
    return { schedules: this.props.schedules };
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
    var that = this;
    var today  = moment();
    var last_hour = 20;
    var current_hour = 7;
    for(; current_hour <= last_hour; current_hour++){
      schedules.push( React.createElement(ScheduleRow, {key: current_hour, hour: current_hour, schedules: this.props.slist}) );
    }
    return ( 
      React.createElement("div", null, 
        React.createElement("h3", null), 
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
    var loop_array = ['-', 'domingo', 'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado']
    var that = this;

    var curr_day = new Date;
    var first_day = curr_day.getDate() - curr_day.getDay();
    var last_day = first_day + 6;

    var week_first_day = new Date( curr_day.setDate( first_day ) );
    var week_last_day = new Date( curr_day.setDate( last_day ) );
    
    var day_count = 1;
    return (
      React.createElement("tr", null, 
        
          loop_array.map( function( day ) {
            var row_text = '';
            var class_row = '';
            if( day === '-' ){
              day_count = 0;;
            } else{
              var active_day = moment( week_first_day ).seconds(0).minute(0).hour(that.props.hour);
              active_day.add(day_count, 'days');
              row_text = active_day.format('MMMM D, HH:mm');
              day_count++;
              _.each(that.props.schedules, function( schedule ){
                  var schedule_day = moment( schedule.datetime );
                  var schedule_hours = parseFloat(schedule.estimated_hours);
                  var schedule_time = moment( schedule.datetime ).add( schedule_hours.toFixed(), 'hour');

                  if( moment( active_day.format() ).isBetween( schedule_day.format(), schedule_time.format() ) ){
                    row_text = schedule.user.full_name;
                    class_row = 'schedule_on';
                  }
                
                /*
                if( schedule.service_type_id === 2 ){
                  if( moment( active_day.format() ).isSame( schedule_day.format() ) ){
                    class_row = 'schedule_on';
                  }
                }*/
                //console.log('Samedate: ', active_day.format(), schedule_day.format() ); 
              });
            }
            return React.createElement(ScheduleCell, {key: day, text: row_text, class_name: class_row });
          })
        
      )
    );
  }
});

var ScheduleCell = React.createClass({displayName: "ScheduleCell",
  render: function() {
    var rowStyle = { width: '12.5%'};
    return React.createElement("td", {style: rowStyle, className: this.props.class_name}, this.props.text);
  }
});

$.ajax({
  url: url_aliada,
  dataType: 'json'
}).done( function( data ) {
  React.render( React.createElement(SchedulesApp, {schedules: data}), document.getElementById( "SchedulesApp" ) );
});
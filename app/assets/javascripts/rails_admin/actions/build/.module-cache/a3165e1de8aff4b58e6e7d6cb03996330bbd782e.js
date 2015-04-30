var final_countdown = '';
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
    var week_table_array = ['hour', 'sun', 'mon', 'tue', 'wed', 'thu', 'fry', 'sat']
    var that = this;

    return (
      React.createElement("tr", null, 
        
          week_table_array.map( function( day ) {
            var hour = moment( that.props.hour, 'HH');
            var class_name = day + '_' + hour.format('HH');
            var row_text = '';
            if( day === 'hour' ){
              row_text = hour.format('HH:mm');
            }
            return React.createElement(ScheduleCell, {key: class_name, text: row_text, class_name: class_name });
          })
        
      )
    );
  }
});

var ScheduleCell = React.createClass({displayName: "ScheduleCell",
  render: function() {
    return (React.createElement("td", {className: this.props.class_name}, React.createElement("div", null, this.props.text)));
  }
});

$.ajax({
  url: url_aliada,
  dataType: 'json'
}).done( function( data ) {
  React.render( React.createElement(SchedulesApp, {schedules: data}), document.getElementById( "SchedulesApp" ) );
});
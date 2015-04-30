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
    for(; current_hour < last_hour; current_hour++){
      schedules.push( React.createElement(ScheduleRow, {hour: current_hour }) );
    }
    /*
    var datetime = moment("2015-05-02T15:00:00.000Z", "YYYY-MM-DD HH:mm Z");

    if( moment().isDST() ){
      datetime.subtract( moment.duration( 1, 'h' ) ).hour()
    }
    console.log( datetime.fromNow(), datetime.hour() );
    
    this.props.slist.forEach( function( schedule ) {
      schedules.push(<Schedule schedule={schedule} /> );
    });*/
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
    var loop_array = ['-','lunes','martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo']
    return (
      React.createElement("tr", null, 
        
          loop_array.map(function(result) {
            console.log( result );
           return React.createElement(ScheduleCell, {text: 'Hola'});
          })
        
      )
    );
  }
});

var ScheduleCell = React.createClass({displayName: "ScheduleCell",
  render: function() {
    var rowStyle = { width: '12.5%'};
    return React.createElement("td", {style: rowStyle}, "Hi: ", this.props.text);
  }
});

$.ajax({
  url: url_aliada,
  dataType: 'json'
}).done( function( data ) {
  React.render( React.createElement(SchedulesApp, {schedules: data}), document.getElementById( "SchedulesApp" ) );
});
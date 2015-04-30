var SchedulesApp = React.createClass({displayName: "SchedulesApp",

  getInitialState: function() {    
    return { schedules: this.props.schedules };
  },

  render: function() {
    var tableStyle = {};
    var leftTdStyle = {};
    var rightTdStyle = {};
    console.log( this.state.schedules );
    return ( 
      React.createElement("table", {style: tableStyle}, 
        React.createElement("tr", null, 
          React.createElement("td", {style: leftTdStyle}, 
            React.createElement(SchedulesList, {slist: this.state.schedules})
          ), 
          React.createElement("td", {style: rightTdStyle}
          )
        )
    )
    );
  }

});

var SchedulesList = React.createClass({displayName: "SchedulesList",
  render: function() {
    var schedules = [];
    var that = this; // TODO: Needs to find out why that = this made it work; Was getting error that onCompanyDelete is not undefined
    this.props.slist.forEach( function( schedule ) {
      schedules.push(React.createElement(Schedule, {schedule: schedule}) );
    });
    return ( 
      React.createElement("div", null, 
        React.createElement("h3", null), 
        React.createElement("table", {className: "table table-striped"}, 
          React.createElement("thead", null, React.createElement("tr", null, React.createElement("th", null), React.createElement("th", null, "Domingo"), React.createElement("th", null, "Lunes"), React.createElement("th", null, "Martes"), React.createElement("th", null, "Miércoles"), React.createElement("th", null, "Jueves"), React.createElement("th", null, "Viernes"), React.createElement("th", null, "Sábado"))), 
          React.createElement("tbody", null, schedules)
        )
      )
      );
  }
});

var Schedule = React.createClass({displayName: "Schedule",
  render: function() {
    return (
      React.createElement("tr", null, 
        React.createElement("td", null), 
        React.createElement("td", null, this.props.schedule.user_id), 
        React.createElement("td", null, this.props.schedule.estimated_hours), 
        React.createElement("td", null, this.props.schedule.hours_after_service), 
        React.createElement("td", null), 
        React.createElement("td", null), 
        React.createElement("td", null), 
        React.createElement("td", null)
      )
      );
  }
});

var url = '/rails_admin/aliada/get_schedule/897';
$.ajax({
  url,
  dataType: 'json'
}).done( function( data ) {
  React.render( React.createElement(SchedulesApp, {schedules: data}), document.getElementById( "SchedulesApp" ) );
});

var now = new Date();
var day = now.getDay();
var month = now.getMonth();


console.log( day );
console.log( month );

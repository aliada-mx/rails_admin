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
            React.createElement(SchedulesList, {clist: this.state.companylist})
          ), 
          React.createElement("td", {style: rightTdStyle}
          )
        )
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

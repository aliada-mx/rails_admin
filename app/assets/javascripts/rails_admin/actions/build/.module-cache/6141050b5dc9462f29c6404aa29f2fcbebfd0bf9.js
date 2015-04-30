var SchedulesApp = React.createClass({displayName: "SchedulesApp",

  getInitialState: function() {    
    return { schedules: this.props.schedules };
  },

  render: function() {
    var tableStyle = {};
    var leftTdStyle = {};
    var rightTdStyle = {};
    return ( 
      React.createElement("table", {style: tableStyle}, 
        React.createElement("tr", null, 
          React.createElement("td", {style: leftTdStyle}, 
            React.createElement(CompanyList, {clist: this.state.companylist, onCompanyRemove: this.handleCompanyRemove})
          ), 
          React.createElement("td", {style: rightTdStyle}, 
            React.createElement(NewRow, {onRowSubmit: this.handleNewRowSubmit})
          )
        )
    )
    );
  }

});

var url = '/rails_admin/aliada/get_schedule/897';
var schedules = [];
$.ajax({
  url,
  dataType: 'json'
}).done( function( data ) {
  schedules =  data;
  React.render( React.createElement(SchedulesApp, {schedules: schedules}), document.getElementById( "SchedulesApp" ) );
});

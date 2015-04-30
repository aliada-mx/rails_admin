var SchedulesApp = React.createClass({displayName: "SchedulesApp",
  getInitialState: function() {
    return {companylist:this.props.companies};
  },

  handleNewRowSubmit: function( newcompany ) {
    this.setState( {companylist: this.state.companylist.concat([newcompany])} );
  },
  handleCompanyRemove: function( company ) {
    var index = -1;	
    var clength = this.state.companylist.length;
		for( var i = 0; i < clength; i++ ) {
			if( this.state.companylist[i].cname === company.cname ) {
				index = i;
				break;
			}
		}
		this.state.companylist.splice( index, 1 );	
		this.setState( {companylist: this.state.companylist} );
  },
  render: function() {

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

var CompanyList = React.createClass({displayName: "CompanyList",
  handleCompanyRemove: function(company){
    this.props.onCompanyRemove( company );
  },
  render: function() {
    var companies = [];
    var that = this; // TODO: Needs to find out why that = this made it work; Was getting error that onCompanyDelete is not undefined
    this.props.clist.forEach(function(company) {
      companies.push(React.createElement(Company, {company: company, onCompanyDelete: that.handleCompanyRemove}) );
    });
    return ( 
      React.createElement("div", null, 
        React.createElement("h3", null, "List of Companies"), 
        React.createElement("table", {className: "table table-striped"}, 
          React.createElement("thead", null, React.createElement("tr", null, React.createElement("th", null, "Company Name"), React.createElement("th", null, "Employees"), React.createElement("th", null, "Head Office"), React.createElement("th", null, "Action"))), 
          React.createElement("tbody", null, companies)
        )
      )
      );
  }
});

var Company = React.createClass({displayName: "Company",
  handleRemoveCompany: function() {
    this.props.onCompanyDelete( this.props.company );
    return false;
  },
  render: function() {
    return (
      React.createElement("tr", null, 
        React.createElement("td", null, this.props.company.cname), 
        React.createElement("td", null, this.props.company.ecount), 
        React.createElement("td", null, this.props.company.hoffice), 
        React.createElement("td", null, React.createElement("input", {type: "button", className: "btn btn-primary", value: "Remove", onClick: this.handleRemoveCompany}))
      )
      );
  }
});

var NewRow = React.createClass({displayName: "NewRow",
  handleSubmit: function() {
    var cname = this.refs.cname.getDOMNode().value;
    var ecount = this.refs.ecount.getDOMNode().value;
    var hoffice = this.refs.hoffice.getDOMNode().value;
    var newrow = {cname: cname, ecount: ecount, hoffice: hoffice };
    this.props.onRowSubmit( newrow );
    
    this.refs.cname.getDOMNode().value = '';
    this.refs.ecount.getDOMNode().value = '';
    this.refs.hoffice.getDOMNode().value = '';
    return false;
  },
  render: function() {
    var inputStyle = {padding:'12px'}
    return ( 
      React.createElement("div", {className: "well"}, 
        React.createElement("h3", null, "Add A Company"), 
      React.createElement("form", {onSubmit: this.handleSubmit}, 
        React.createElement("div", {className: "input-group input-group-lg", style: inputStyle}, 
          React.createElement("input", {type: "text", className: "form-control col-md-8", placeholder: "Company Name", ref: "cname"})
        ), 
        React.createElement("div", {className: "input-group input-group-lg", style: inputStyle}, 
          React.createElement("input", {type: "text", className: "form-control col-md-8", placeholder: "Employee Count", ref: "ecount"})
        ), 
        React.createElement("div", {className: "input-group input-group-lg", style: inputStyle}, 
          React.createElement("input", {type: "text", className: "form-control col-md-8", placeholder: "Headoffice", ref: "hoffice"})
        ), 
        React.createElement("div", {className: "input-group input-group-lg", style: inputStyle}, 
          React.createElement("input", {type: "submit", className: "btn btn-primary", value: "Add Company"})
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
  console.log( data );
});

var defCompanies = [{cname:"Infosys Technologies",ecount:150000,hoffice:"Bangalore"},{cname:"TCS",ecount:140000,hoffice:"Mumbai"}];
React.render( React.createElement(SchedulesApp, {companies: defCompanies}), document.getElementById( "SchedulesApp" ) );
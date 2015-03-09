//= require jquery
//= require jquery-ui.min.js
//= require jquery.blockUI
//= require jquery.form.min
//= require modernizr.custom.63321
//
//= require knockout
//= require knockout.validation
//= require knockout_custom_bindings
//
//= require underscore
//= require bluebird.min
//= require vex
//= require vex.dialog
//
//= require js-routes
//
//= require aliada_exceptions
//= require_self

vex.defaultOptions.className = 'vex-theme-plain';

// Config blockUI
_.extend($.blockUI.defaults.css,{
    border: 'none',
    padding: '20px'
})

// Utility log
log = function(message,object){
    if(window.console){
        console.log(message);
        if (typeof(message) === 'object'){
            console.dir(message);
            return;
        }
        if (typeof(object) !== 'undefined'){
            console.dir(object);
            console.log('-------------');
            return;
        }
    }
};

// Add csrf token to ajax requests
add_csrf_token = function(xhr) {
  xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
}

// Enable long stack traces for Bluebird.js
if(aliada.rails_environment == 'development'){
    Promise.longStackTraces();
}
// Block the user browser interaction
aliada.block_ui = function(){
    var aliada_busy_message = _.template($('#aliada_busy_message_template').html());

    $.blockUI({ message: aliada_busy_message(), blockMsgClass: 'blocked_ui_dialog', });
};

// Unblock the user browser interaction
aliada.unblock_ui = function(){
    $.unblockUI();
}

// Configure underscore template interpolation to use {{ variable }}
_.templateSettings = {
  evaluate:    /\{\{#([\s\S]+?)\}\}/g,            // {{# console.log("blah") }}
  interpolate: /\{\{[^#\{]([\s\S]+?)[^\}]\}\}/g,  // {{ title }}
  escape:      /\{\{\{([\s\S]+?)\}\}\}/g,         // {{{ title }}}
}

// Utility to redirect to some url
function redirect_to(url){
  window.location.replace(url);
}

//= require jquery
//= require jquery-ui.min.js
//
//= require modernizr.custom.63321
//= require underscore
//= require bluebird.min
//
//= require knockout
//= require knockout.validation
//= require knockout_custom_bindings
//
//= require vex
//= require vex.dialog
//
//= require js-routes
//= require jquery.form.min
//= require_self

vex.defaultOptions.className = 'vex-theme-plain';

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

add_csrf_token = function(xhr) {
  xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
}

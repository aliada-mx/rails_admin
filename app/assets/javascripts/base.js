//= require jquery
//= require jquery-ui.min.js
//= require jquery.validate
//
//= require modernizr.custom.63321
//= require underscore
//= require bluebird.min
//
//= require knockout
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

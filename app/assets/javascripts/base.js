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
//= require isMobile
//= require underscore
//= require bluebird.min
//= require vex
//= require vex.dialog
//
//= require js-routes
//
//= require aliada_exceptions
//= require utilities
//= require_self

// Libraries configuration

vex.defaultOptions.className = 'vex-theme-plain';

// Catch exceptions with raygun
// Raygun.init(raygun_api_key).attach();

// Config blockUI
_.extend($.blockUI.defaults.css,{
  border: 'none',
  padding: '20px'
});

// Add csrf token to ajax requests
add_csrf_token = function(xhr) {
  xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
};

// Enable long stack traces for Bluebird.js
if(aliada.rails_environment == 'development'){
  Promise.longStackTraces();
}

// Configure underscore template interpolation to use {{ variable }}
_.templateSettings = {
  evaluate:    /\{\{#([\s\S]+?)\}\}/g,            // {{# console.log("blah") }}
  interpolate: /\{\{[^#\{]([\s\S]+?)[^\}]\}\}/g,  // {{ title }}
  escape:      /\{\{\{([\s\S]+?)\}\}\}/g,         // {{{ title }}}
};


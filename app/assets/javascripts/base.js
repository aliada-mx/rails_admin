//= require jquery
//= require modernizr.custom.63321
//= require underscore
//= require knockout
//= require_self

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


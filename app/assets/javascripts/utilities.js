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


function report_error(e){
    Raygun.send(e, {ko: ko.toJSON(aliada.ko) });
}

// Block the user browser interaction
aliada.block_ui = function(){
  var aliada_busy_message = _.template($('#aliada_busy_message_template').html());

  $.blockUI({ message: aliada_busy_message(), blockMsgClass: 'blocked_ui_dialog', });
};

// Unblock the user browser interaction
aliada.unblock_ui = function(){
  $.unblockUI();
};
  
// Utility to redirect to some url
function redirect_to(url){
  window.location.replace(url);
};

// Utility function for smooth scrolling with a href='#id'
initialize_scroll_anchors = function(){
  $('a[href*=#]').on('click', function(event){     
    event.preventDefault();
    smooth_scroll(this.hash);
  });
}

smooth_scroll = function(target){
  $('html,body').stop().animate({scrollTop:$(target).offset().top - 20}, 500);
}


aliada.highlighted_element = undefined;

function highlight(element){
    if(typeof aliada.highlighted_element === 'undefined' || aliada.highlighted_element != element){
        unhighlight(aliada.highlighted_element);
    }
    pulsate(element);
    aliada.highlighted_element = element;

    window.setTimeout(function(){
        unhighlight(element);
    },3000)

    function pulsate(element){
        $(element).pulsate({
          color: "#12B795", // set the color of the pulse
          reach: 10,                              // how far the pulse goes in px
          speed: 1000,                            // how long one pulse takes in ms
          pause: 0,                               // how long the pause between pulses is in ms
          glow: true,                             // if the glow should be shown too
          repeat: true,                           // will repeat forever if true, if given a number will repeat for that many times
          onHover: false                          // if true only pulsate if user hovers over the element
        });
    }
}

function unhighlight(element){
    $(element).pulsate('destroy');
}

function update_calendar(){
  $.event.trigger({type: 'update-calendar'});
}

function isNumber(obj) {
  return toString.call(obj) == '[object Number]';
}

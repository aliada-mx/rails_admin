//= require modules/geo-autocomplete
//= require modules/map

aliada.services.initial.step_2_personal_info = function(aliada, ko){
  var name_email_phone_default = 'Nombre, correo, teléfono';
  var address_default = 'Dirección';

  var on_step_2 = function(){ return aliada.ko.current_step() == 2 };

  // Knockout model

  // Batch extend and validate required
  aliada.step_2_required_fields = [ 'first_name',
                                    'email',
                                    'last_name',
                                    'phone',
                                    'street',
                                    'number',
                                    'colony',
                                    'between_streets',
                                    'city',
                                    'state',
                                    'postal_code_number' ]
  _.each(aliada.step_2_required_fields, function(element){
    aliada.ko[element] = ko.observable('').extend({ required: { onlyIf: on_step_2 } })
  });

  _(aliada.ko).extend({
    email: ko.observable('').extend({
      email: true
    }),
    latitude: ko.observable(''),
    longitude: ko.observable(''),
    interior_number: ko.observable(''),
    map_zoom: ko.observable(aliada.default_map_zoom),
  });


  // PERSONAL INFO
  aliada.ko.name_email_phone = ko.computed(function(){
      var name_email_phone = '';

      if(aliada.ko.email()){
        name_email_phone += aliada.ko.email();
      }
      if(aliada.ko.first_name()){
        name_email_phone += ', ';
        name_email_phone += aliada.ko.first_name();
      }
      if(aliada.ko.last_name()){
        name_email_phone += ' ';
        name_email_phone += aliada.ko.last_name();
      }
      if(aliada.ko.phone()){
        name_email_phone += ', ';
        name_email_phone += aliada.ko.phone();
      }

      return name_email_phone === '' ? name_email_phone_default : name_email_phone;
  });

  // Is the step done
  aliada.ko.is_name_email_phone_done = ko.computed(function(){
    return aliada.ko.name_email_phone() != name_email_phone_default;
  })


  // ADDRESS INFO
  // Build address string
  aliada.ko.address = ko.computed(function(){
    address = '';

    if(aliada.ko.street()){
      address += aliada.ko.street();
    }
    if(aliada.ko.number()){
      address += ' '
      address += aliada.ko.number();
    }
    if(aliada.ko.interior_number()){
      address += ', int. ';
      address += aliada.ko.interior_number();
    }
    if(aliada.ko.colony()){
      address += ', colonia ';
      address += aliada.ko.colony();
    }
    if(aliada.ko.city()){
      address += ', ';
      address += aliada.ko.city();
    }

    return address === '' ? address_default : address;
  });

  // Is the step done
  aliada.ko.is_address_done = ko.computed(function(){
    return aliada.ko.address() != address_default;;
  });


  var initialize_map_and_autocomplete = function(){
    // Our autocomplete input
    var $street_input = $('#service_address_street');

    // Set variables from the autocomplete
    aliada.geo_autocomplete($street_input[0], function(address){
      // Address object keys are also viewmodels keys
      _.each(address, function(value,key){
        aliada.ko[key](value);
      });

      // Trigger postal code checking because ko by default
      // does not trigger change event when setting new values
      if (!_.isEmpty(address['postal_code_number'])){
        $('#service_address_postal_code_number').trigger('change');
      }

      update_map_center(address.latitude,address.longitude);
    });

    // Map
    var $map_container = $('#map-container');
    var marker_map = aliada.initialize_map($map_container[0])
    var map = marker_map.map;
    var marker = marker_map.marker;

    // Map event listeners
    google.maps.event.addListener(map, 'zoom_changed', function(){
      aliada.ko.map_zoom(map.getZoom());
    });

    google.maps.event.addListener(marker, 'mouseup', function(){
      aliada.ko.latitude(marker.position.lat());
      aliada.ko.longitude(marker.position.lng());
    });

    var update_map_center = function(latitude,longitude){
      var center = new google.maps.LatLng(latitude, longitude);

      marker.setPosition(center);
      map.panTo(center);
    }

    // Select on click
    $street_input.click(function(){
      $(this).select();
    });

    // Do not submit on enter, let the user select with enter
    google.maps.event.addDomListener($street_input[0], 'keydown', function(e) { 
      if (e.keyCode == 13) { 
          e.preventDefault(); 
      }
    }); 
  }

  var should_init_map_autocomplete = true;

  // On entering the step
  $(document).on('entering_step_2',function(){
    // Initialize map only once the container is visible otherwise the map renders incorrectly
    if(should_init_map_autocomplete){
      initialize_map_and_autocomplete();
      should_init_map_autocomplete = false;
    }
  });
}

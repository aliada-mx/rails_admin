//= require modules/geo-complete.js
//

$(function() {
  var initialize_map_and_autocomplete = function() {
    // Our autocomplete input
    var $street_input = $('#service_address_street');

    // Set variables from the autocomplete
    aliada.geo_autocomplete($street_input[0], function(address) {
      // Address object keys are also viewmodels keys
      _.each(address, function(value, key) {
        aliada.ko[key](value);
      });

      update_map_center(address.latitude, address.longitude);
    });

    // Map
    var $map_container = $('#map-container');
    var marker_map = aliada.initialize_map($map_container[0])
    var map = marker_map.map;
    var marker = marker_map.marker;

    // Map event listeners
    google.maps.event.addListener(map, 'zoom_changed', function() {
      aliada.ko.map_zoom(map.getZoom());
    });

    google.maps.event.addListener(marker, 'mouseup', function() {
      aliada.ko.latitude(marker.position.lat());
      aliada.ko.longitude(marker.position.lng());
    });

    var update_map_center = function(latitude, longitude) {
      var center = new google.maps.LatLng(latitude, longitude);

      marker.setPosition(center);
      map.panTo(center);
    }

    // Select on click
    $street_input.click(function() {
      $(this).select();
    });

    // Do not submit on enter, let the user select with enter
    google.maps.event.addDomListener($street_input[0], 'keydown', function(e) {
      if (e.keyCode == 13) {
        e.preventDefault();
      }
    });
  }
})

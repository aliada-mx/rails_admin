//= require minimal
//= require underscore
//= require knockout
//= require knockout.mapping-latest.js
//= require modules/geo-autocomplete.js
//= require modules/map
//
//

function add_references_marker(map, latitude, longitude){
  var references_marker_center = new google.maps.LatLng(latitude, longitude);
  var references_marker = new google.maps.Marker({
      map: map,
      draggable: true,
      animation: google.maps.Animation.DROP,
      position: references_marker_center ,
      icon: 'http://maps.google.com/mapfiles/ms/icons/blue-dot.png',
  });

  google.maps.event.addListener(references_marker, 'mouseup', function() {
    aliada.ko.references_latitude(references_marker.position.lat());
    aliada.ko.references_longitude(references_marker.position.lng());
  });

  return references_marker;
}

var update_map_center = function(map, latitude, longitude) {
  var center = new google.maps.LatLng(latitude, longitude);

  map.panTo(center);
}

var move_marker = function(marker, latitude, longitude){
  var center = new google.maps.LatLng(latitude, longitude);

  marker.setPosition(center);
}

$(function() {
  // Our autocomplete input
  var $street_input = $('#address_street');
  var references_marker = null;

  aliada.ko = ko.mapping.fromJS(aliada.address_json);

  aliada.ko.references_added = ko.computed(function(){
    return !_.isEmpty(aliada.ko.references_latitude()) && !_.isEmpty(aliada.ko.references_longitude()) 
  }),
    
  // Activates knockout.js
  ko.applyBindings(aliada.ko);

  // Set variables from the autocomplete
  aliada.geo_autocomplete($street_input[0], function(address) {
    // Address object keys are also viewmodels keys
    _.each(address, function(value, key) {
      aliada.ko[key](value);
    });

    update_map_center(map, address.latitude, address.longitude);

    move_marker(marker, address.latitude, address.longitude);

    move_marker(marker, address.latitude, address.longitude);
  });

  // Map
  var map_center_latitude = aliada.ko.map_center_latitude() || aliada.ko.latitude();
  var map_center_longitude = aliada.ko.map_center_longitude() || aliada.ko.longitude();

  var $map_container = $('#map-container');
  var marker_map = aliada.initialize_map($map_container[0], map_center_latitude, map_center_longitude);
  var map = marker_map.map;
  var marker = marker_map.marker;

  update_map_center(map, map_center_latitude, map_center_longitude);
  move_marker(marker, aliada.ko.latitude(), aliada.ko.longitude())

  // Map event listeners
  google.maps.event.addListener(map, 'zoom_changed', function() {
    aliada.ko.map_zoom(map.getZoom());
  });
  
  google.maps.event.addListener(map, 'center_changed', function() {
    aliada.ko.map_center_latitude(map.center.lat());
    aliada.ko.map_center_longitude(map.center.lng());
  });

  google.maps.event.addListener(marker, 'mouseup', function() {
    aliada.ko.latitude(marker.position.lat());
    aliada.ko.longitude(marker.position.lng());
  });

  if (aliada.ko.references_added()){
    references_marker = add_references_marker(map, aliada.ko.references_latitude(), aliada.ko.references_longitude());
  }

  $('#add_references_marker_button').click(function(){
    // Delete previous
    if(references_marker !== null){
      references_marker.setMap(null);
    }

    references_marker = add_references_marker(map, map_center_latitude, map_center_longitude);
  });

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
})

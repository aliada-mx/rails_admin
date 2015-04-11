aliada.initialize_map = function(container, latitude, longitude){
  if (_.isUndefined(latitude)){
    var latitude = '19.4007'; // mexico_city_latitude 
  }
  if (_.isUndefined(longitude)){
    var longitude = '-99.1573'; // mexico_city_longitude 
  }

  var center = new google.maps.LatLng(latitude, longitude);

  var myOptions = {
      zoom: aliada.default_map_zoom || 16,
      center: center,
      mapTypeId: google.maps.MapTypeId.ROADMAP
  };
  var map = new google.maps.Map(container, myOptions);

  var marker = new google.maps.Marker({
      map: map,
      draggable: true,
      animation: google.maps.Animation.DROP,
      position: center,
      icon: aliada.map_marker_icon
  });

  return {marker: marker, map: map}
}

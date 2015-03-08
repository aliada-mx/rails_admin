aliada.geo_autocomplete = function(input, success){
  var autocomplete = new google.maps.places.Autocomplete(input,{
    types: ['address'],
    componentRestrictions: { 'country': 'mx' }
  });

  google.maps.event.addListener(autocomplete, 'place_changed', function(){
    var place = autocomplete.getPlace();
    if (!place.geometry) {
      return;
    }

    if (place.address_components) {
        address = {place: place}
        _.each(place.address_components, function(component, i){
          var name = component.types[0];
          var value = component.long_name;
          switch(name){
          case 'street_number':
            address.number = value;
            break;
          case 'route':
            address.street = value;
            break;
          case 'neighborhood':
            address.colony = value;
            break;
          case 'postal_code':
            address.postal_code_number = value;
            break;
          }
        });
      success(address)
    }
  });
}

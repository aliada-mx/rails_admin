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
        address = {};
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
            case 'locality':
              address.colony = value;
            case 'postal_code':
              address.postal_code_number = value;
              break;
            case 'sublocality_level_1':
              address.city = value;
              break;
            }
        });

        address['latitude'] = place.geometry.location.lat();
        address['longitude'] = place.geometry.location.lng();
        success(address)
      }
    });
}

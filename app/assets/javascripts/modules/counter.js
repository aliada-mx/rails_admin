$(function(){
  var $counter_container = $('.counter-container');

  $('.counter-toggle-button').click(function(){
    $counter_container.slideToggle();
    aliada.ko.forced_hours(null);
  })

  $counter_container.on('click',function(e){
    var $button = $(e.target),
        button_action = $button.data('action');

    var bathrooms = aliada.ko.bathrooms();
    var bedrooms = aliada.ko.bedrooms();

    switch(button_action){
      case 'less-bathrooms':
        var new_bathrooms = bathrooms === 1 ? 0 : bathrooms - 1;

        aliada.ko.bathrooms(new_bathrooms)
        break;
      case 'more-bathrooms':
        var new_bathrooms = bathrooms + 1;

        aliada.ko.bathrooms(new_bathrooms)
        break;
      case 'less-bedrooms':
        var new_bedrooms = bedrooms === 1 ? 0 : bedrooms - 1;

        aliada.ko.bedrooms(new_bedrooms)
        break;
      case 'more-bedrooms':
        var new_bedrooms = bedrooms + 1;

        aliada.ko.bedrooms(new_bedrooms)
        break;
    }

  })
});

//= require jquery

$(function(){
    // Adjust the height of the new service card
    // TODO solve on CSS
    var $new_service_card = $('.new-service-card')
    var card_height = $new_service_card.prev().children('.service-card').outerHeight(false);
    
    $new_service_card.css('height', card_height);

})

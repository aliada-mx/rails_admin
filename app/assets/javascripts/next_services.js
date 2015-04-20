//= require minimal

$(function(){
  // Adjust the height of the new service card
  // TODO solve on CSS
  window.setTimeout(function(){
    var $new_service_card_wrapper = $('.service-card-wrapper.empty')
    var card_height = $new_service_card_wrapper.prev().children('.service-card').height();

    $new_service_card_wrapper.find('.service-card').css('height', card_height);
  },100)

})

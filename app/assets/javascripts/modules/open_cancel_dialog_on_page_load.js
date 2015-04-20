aliada.open_cancel_dialog_on_page_load = function(){
  var url = new URI(window.location.href);
  var should_open_cancel_dialog = url.hasQuery('cancelar', true);

  if ( should_open_cancel_dialog ){
    window.setTimeout(function(){
      $('#cancel_button').triggerHandler('click');
    },0);
  }
}

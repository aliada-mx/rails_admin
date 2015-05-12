aliada.previous_services_subaction = function() {
  function show_paypal_success_dialog() {
    aliada.dialogs.paypal_success()
  }

  function show_paypal_cancelation_dialog() {
    aliada.dialogs.paypal_cancelation()
  }

  var url = new URI(window.location.href);
  var subaction = url.hasQuery('subaction') ? url.search(true)['subaction'] : false

  if (!subaction) {
    return
  }

  switch (subaction) {
    case 'paypal_success':
      show_paypal_success_dialog();
      break;
    case 'paypal_cancelation':
      show_paypal_cancelation_dialog();
      break;
  }
}

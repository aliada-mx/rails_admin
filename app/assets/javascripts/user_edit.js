//= require base
//= require modules/conekta
//= require modules/dialogs


$(function() {
  var $conekta_card_form = $('.edit_conekta_card');

  function add_conekta_card() {
    return new Promise(function(resolve, reject) {
      $conekta_card_form.ajaxSubmit({
        dataType: 'json',
        success: function(response) {
          switch (response.status) {
            case 'success':
              resolve(response);
              break;

            case 'error':
              reject(new ConektaFailed(response));
              break;
            case 'warning':
              reject(new ConektaFailed(response.messages[0]));
              break;
          }
        },
        error: function(response) {
          reject(new PlatformError(response));
        }
      });

    });
  }

  function confirm_card_change() {
    return aliada.dialogs.confirm_change_card()
  }

  function show_success_dialog() { 
    aliada.dialogs.succesfull_service_changes(response.next_path);
  }
  

  $conekta_card_form.on('submit', function(e) {
    e.preventDefault();
    var form = this;

    var $token_input = $('#conekta_temporary_token');

    aliada.block_ui();

    aliada.add_conekta_token_to_form(form, $token_input)
      .then(confirm_card_change)
      .then(add_conekta_card)
      .then()
      .caught(ConektaFailed, function(exception) {
        report_error(exception)

        aliada.dialogs.conekta_error(exception.message);
      })
      .finally(function() {
        aliada.unblock_ui();
      });

    return;
  });
});

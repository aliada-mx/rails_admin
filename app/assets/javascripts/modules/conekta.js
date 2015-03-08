aliada.add_conekta_token_to_form = function(form, token_input){
    return new Promise(function(resolve, reject){
      function conektaErrorResponseHandler(response) {
          reject(new ConektaFailed(response.message_to_purchaser));
      }

      function conektaSuccessResponseHandler(token) {
          token_input.val(token.id);
          resolve($form);
      }

      var $form = $(form);

      Conekta.token.create($form, conektaSuccessResponseHandler, conektaErrorResponseHandler);
    });
}


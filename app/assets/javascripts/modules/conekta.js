aliada.add_conekta_token_to_form = function(form, after_error, after_success){
    function conektaErrorResponseHandler(response) {
        after_error(response);
    };

    function conektaSuccessResponseHandler(token) {
        $form.val(token.id);
        after_success($form);
    };

    var $form = $(form);

    Conekta.token.create($form, leco.conektaSuccessResponseHandler, leco.conektaErrorResponseHandler);
}


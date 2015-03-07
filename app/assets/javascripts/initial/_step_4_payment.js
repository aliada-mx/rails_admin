//= require modules/conekta

aliada.services.initial.step_4_payment = function(ko){
  function create_service($form){
    return new Promise(function(resolve,reject){
      $form.ajaxSubmit({
        success: function(response){
          log('service creation response', response)
          switch(response.status){
            case 'success':
              resolve();
              break;

            case 'error':
              reject(new ServiceCreationFailed(response));
              break;
          }
        },
        error: function(response){
          reject(new PlatformError(response));
        }
      });

    });

  }

  function go_to_success(){
    aliada.ko.current_step(5);
  }

  $(aliada.services.initial.form).on('submit', function(e){
    e.preventDefault();
    aliada.block_ui();
    var $token_input = $('#conekta_temporary_token');
    var form = this;

    aliada.add_conekta_token_to_form(form, $token_input)
          .then(create_service)
          .then(go_to_success)
          .caught(ConektaFailed, function(exception){
            aliada.dialogs.conekta_error(exception.message);
          })
          .caught(ServiceCreationFailed, function(exception){
            aliada.dialogs.invalid_service(exception.message);
          })
          .caught(PlatformError, function(exception){
            aliada.dialogs.platform_error(exception.message);
          })
          .caught(function(error){
            aliada.dialogs.platform_error(error);
          })
          .finally(function(){
            aliada.unblock_ui();
          })
  });
}

<<<<<<< HEAD
//= require modules/conekta

aliada.services.initial.step_4_payment = function(aliada, ko){
    _(aliada.ko).extend({
      tos_accepted: ko.observable(false),
    });

  function create_service($form){
    return new Promise(function(resolve,reject){
      $form.ajaxSubmit({
        url: aliada.ko.form_action(),
        success: function(response){
          switch(response.status){
            case 'success':
              resolve(response);
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

  function go_to_success_or_redirect(response){
    if (_(response).has('next_path')){
      redirect_to(response.next_path);
      return;
    }

    aliada.ko.service_id(response.service_id)
    aliada.ko.user_id(response.user_id)

    // Change the form so we can update the service from the same form
    aliada.ko.form_action(aliada.ko.update_service_users_path());

    aliada.ko.current_step(5);
  }

  $(aliada.services.initial.$form).on('submit', function(e){
    e.preventDefault();
    var $token_input = $('#conekta_temporary_token');
    aliada.block_ui();
    var form = this;

    aliada.add_conekta_token_to_form(form, $token_input)
          .then(create_service)
          .then(go_to_success_or_redirect)
          .caught(ConektaFailed, function(exception){
            report_error(exception)

            aliada.dialogs.conekta_error(exception.message);
          })
          .caught(ServiceCreationFailed, function(exception){
            report_error(exception)

            aliada.dialogs.invalid_service(exception.message);
          })
          .caught(PlatformError, function(exception){
            report_error(exception)

            aliada.dialogs.platform_error(exception.message);
          })
          .caught(function(exception){
            report_error(exception)

            aliada.dialogs.platform_error(error);
          })
          .finally(function(){
            aliada.unblock_ui();
          })
  });
}
||||||| merged common ancestors
=======
//= require modules/conekta

aliada.services.initial.step_4_payment = function(aliada, ko){
    _(aliada.ko).extend({
      tos_accepted: ko.observable(false),
    });

  function create_service($form){
    return new Promise(function(resolve,reject){
      $form.ajaxSubmit({
        url: aliada.ko.form_action(),
        success: function(response){
          switch(response.status){
            case 'success':
              resolve(response);
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

  function go_to_success_or_redirect(response){
    if (_(response).has('next_path')){
      redirect_to(response.next_path);
      return;
    }

    aliada.ko.service_id(response.service_id)
    aliada.ko.user_id(response.user_id)

    // Change the form so we can update the service from the same form
    aliada.ko.form_action(aliada.ko.update_service_users_path());

    aliada.ko.current_step(5);
  }

  $(aliada.services.initial.$form).on('submit', function(e){
    e.preventDefault();
    aliada.block_ui();
    var $token_input = $('#conekta_temporary_token');
    var form = this;

    aliada.add_conekta_token_to_form(form, $token_input)
          .then(create_service)
          .then(go_to_success_or_redirect)
          .caught(ConektaFailed, function(exception){
            report_error(exception)

            aliada.dialogs.conekta_error(exception.message);
          })
          .caught(ServiceCreationFailed, function(exception){
            report_error(exception)

            aliada.dialogs.invalid_service(exception.message);
          })
          .caught(PlatformError, function(exception){
            report_error(exception)

            aliada.dialogs.platform_error(exception.message);
          })
          .caught(function(exception){
            report_error(exception)

            aliada.dialogs.platform_error(error);
          })
          .finally(function(){
            aliada.unblock_ui();
          })
  });
}
>>>>>>> master

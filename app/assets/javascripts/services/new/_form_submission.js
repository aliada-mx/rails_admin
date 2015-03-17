aliada.services.new.bind_form_submission = function($form){
  function create_service($form){
    return new Promise(function(resolve,reject){
      $form.ajaxSubmit({
        url: aliada.services.new.form_action,
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

    // Change the form so we can update the service from the same form
    aliada.services.new.form_action = Routes.update_service_users_path({user_id: aliada.user.id,
                                                                        service_id: response.service_id})

    aliada.ko.current_step(2);
    smooth_scroll('#success-title');
  }

  $form.on('submit', function(e){
    e.preventDefault();
    aliada.block_ui();

    create_service($form).then(go_to_success_or_redirect)
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
       
                          aliada.dialogs.platform_error(exception);
                        })
                        .finally(function(){
                          aliada.unblock_ui();
                        })
  });
}

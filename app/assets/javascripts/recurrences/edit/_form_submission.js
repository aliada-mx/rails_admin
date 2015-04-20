aliada.recurrence.edit.bind_form_submission = function($form) {
  function update_service($form) {
    return new Promise(function(resolve, reject) {
      data = {}
      data[clicked_button] = true // The clicked button is stored at the original DOM form
      $form.ajaxSubmit({
        data: data,
        success: function(response) {
          switch (response.status) {
            case 'success':
              resolve(response);
              break;

            case 'error':
              reject(new ServiceCreationFailed(response));
              break;
          }
        },
        error: function(response) {
          reject(new PlatformError(response));
        }
      });

    });

  }

  function go_to_success_or_redirect(response) {
    if (_(response).has('next_path')) {
      aliada.dialogs.succesfull_service_changes(response.next_path);
      return;
    }
    aliada.ko.current_step(2);
    smooth_scroll('#success-title');
  }

  $('#update_button, #cancel_button').on('click',function(e){
    e.preventDefault();
    clicked_button = this.name;
    $(this.form).submit();
  })

  var clicked_button = null;

  $form.on('submit', function(e) {
    e.preventDefault();

    if(clicked_button == 'cancel_button'){
      aliada.dialogs.confirm_recurrence_cancel().then(submit)
    }else if(clicked_button == 'update_button'){
      aliada.dialogs.confirm_recurrent_service_change().then(submit)
    }

    function submit(){
      aliada.block_ui();

      update_service($form).then(go_to_success_or_redirect)
        .caught(ServiceCreationFailed, function(exception) {
          report_error(exception)

          aliada.dialogs.invalid_service(exception.message);
        })
        .caught(PlatformError, function(exception) {
          report_error(exception)

          aliada.dialogs.platform_error(exception.message);
        })
        .caught(function(exception) {
          report_error(exception)

          aliada.dialogs.platform_error(exception);
        })
        .finally(function() {
          aliada.unblock_ui();
        })
    }
  });
}

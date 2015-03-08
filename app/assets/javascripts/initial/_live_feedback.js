aliada.services.initial.live_feedback = function($form){
  function save_incomplete_service(){
    $form.ajaxSubmit({
      url: Routes.save_incomplete_service_path(),
      error: function(response){
        aliada.dialogs.platform_error('No se pudo verificar el email');
      }
    });
  };

  function check_email(){
    $form.ajaxSubmit({
      url: Routes.check_email_path(),
      success: function(response){
        if (response.status == 'error'){
          var email = aliada.ko.email();

          aliada.dialogs.email_already_exists(email);
          aliada.ko.email(''); // Delete it to invalidate the form
          $form.find('#service_user_email').select();
        }
      },
      error: function(response){
        aliada.dialogs.platform_error('No se pudo verificar el código postal');
      }
    });
  };

 function check_postal_code(){
    $form.ajaxSubmit({
      url: Routes.check_postal_code_path(),
      success: function(response){
        if (response.status == 'error'){
          var postal_code_number = aliada.ko.postal_code_number();

          aliada.dialogs.postal_code_number_missing(postal_code_number);
          aliada.ko.current_step(2);
          aliada.ko.postal_code_number(''); // Delete it to invalidate the form
          $form.find('#service_address_postal_code_number').select();
        }
      },
      error: function(response){
        reject(new PlatformError(response));
      }
    })
  };

  $form.on('change',function(e){
    var $input = $(e.target);

    switch($input.attr('id')){
      case 'service_user_email':
        check_email();
        break;
      case 'service_address_postal_code_number':
        check_postal_code();
        break;
      default:
        save_incomplete_service();
        break;
    }

  })
}

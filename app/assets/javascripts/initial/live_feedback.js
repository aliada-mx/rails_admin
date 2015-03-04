aliada.services.initial.live_feedback = function($form){
// Contacts the server to verify email, postal code and save an incomplete service
  get_feedback = function(){
    $form.ajaxSubmit({
      url: Routes.initial_feedback_path(),
      success: function(response){
        if (response.status == 'error'){
          switch(response.code){
            case 'email_already_exists':
              var email = aliada.ko.email();

              aliada.dialogs.email_already_exists(email);
              aliada.ko.email(''); // Delete it to invalidate the form
              $form.find('#service_user_email').select();
              break;
            case 'postal_code_missing':
              var postal_code = aliada.ko.postal_code();

              aliada.dialogs.postal_code_missing(postal_code);
              aliada.ko.postal_code(''); // Delete it to invalidate the form
              $form.find('#service_address_postal_code_number').select();
              break;
          }
        }else if(response.status == 'success'){
          $form.find('.invalid')
        }
      },
      error: function(){
        aliada.dialogs.platform_error();
      }
    })
  }

  $form.on('change', get_feedback)
}

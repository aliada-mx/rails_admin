// Contacts the server to verify email, postal code and save an incomplete service
aliada.services.initial.live_feedback = function($form){
  get_feedback = function(){
    $form.ajaxSubmit({
      url: Routes.initial_feedback_path(),
      success: function(response){
        if (response.status == 'error'){
          switch(response.code){
            case 'email_already_exists':
              var email = aliada.ko.email()

              aliada.dialogs.email_already_exists(email);
              break;
            case 'postal_code_missing':
              var postal_code = aliada.ko.postal_code()

              aliada.dialogs.postal_code_missing(postal_code);
              break;
          }
        }
      },
      error: function(){
        aliada.dialogs.platform_error();
      }
    })
  }

  $form.find('input, select').on('change', get_feedback)
}

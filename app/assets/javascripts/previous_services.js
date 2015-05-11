//= require base
//= require URI.min
//= require modules/dialogs
//= require jquery.tablesorter.js
//= require modules/previous_services_subaction

$(function() {
  $('.table').tablesorter();

  $('.score_service input[type=radio]').click(function(){
    var $form = $(this).parent('form');
    var value = $(this).val();

    disableForm($form, value);

    $form.ajaxSubmit({
      dataType: 'json',
      error: function(response) {
        aliada.dialogs.platform_error(response.responseText);
      }
    });
  });

  disableForm = function(form, value) {
    form.children('.unchecked').each(function() {
      $(this).toggleClass('unchecked');
      // selected, submitted value
      if (value == this.value) {
        $(this).toggleClass('checked');
      } else {
        $(this).toggleClass('disabled');
      }
      $(this).prop("onclick", null);
    });
  };

  function get_paypal_url(service_id) {
    return new Promise(function(resolve,reject){
      $.ajax(Routes.get_paypal_redirect_url_users_path(aliada.user.id), {
        method: 'POST',
        dataType: 'json',
        beforeSend: add_csrf_token,
        data: { service_id: service_id },
      }).done(function(response){
        if(response.status == 'success'){
          resolve(response.paypal_pay_url)
        }
      }).fail(function(response){
        reject(new PlatformError(response));
      })
    })
  };

  function redirect_to_paypal(url){
    redirect_to(url);
  }

  function bind_pay_debt_dialog(){
    $('.pay_debt_dialog').on('click', '.pay-button', function() {
      var provider = $(this).data('provider');
      var service_id = $(this).data('service_id');

      // Close dialog
      var $closable_area = $('.vex-overlay');
      $closable_area.trigger('click');

      switch (provider) {
        case 'paypal_express':
          aliada.block_ui();
          get_paypal_url(service_id).then(redirect_to_paypal)
                                    .caught(PlatformError, function(exception){
                                      report_error(exception)
                   
                                      aliada.dialogs.platform_error(exception.message);

                                      aliada.unblock_ui();
                                    });
          break;
      }
    });
  };

  // Paypal success, cancel dialog
  aliada.previous_services_subaction();

  $('.open-payment-dialog').click(function() {
    var service_id = $(this).data('service-id');
    var amount = $(this).data('amount');

    aliada.dialogs.pay_debt({
      service_id: service_id,
      amount: amount,
      afterOpen: bind_pay_debt_dialog
    });
  });
});

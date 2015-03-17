//= require jquery.autogrow-textarea

aliada.services.initial.step_5_success = function(aliada, ko){

  _(aliada.ko).extend({
    service_id: ko.observable(''),
    user_id: ko.observable(''),
  });
  
  aliada.ko.update_service_users_path = ko.computed(function(){
    return Routes.update_service_users_path({ user_id: aliada.ko.user_id(), service_id: aliada.ko.service_id() })
  });

  $(document).on('entering_step_5', function(){
    $('textarea').css('overflow', 'hidden').autogrow();
  });

}

aliada.services.initial.step_2_personal_info = function(aliada, ko){

  _(aliada.ko).extend({
    address: ko.observable('Dirección'),
    name_email_phone: ko.observable('Nombre, correo, teléfono')
  });

}

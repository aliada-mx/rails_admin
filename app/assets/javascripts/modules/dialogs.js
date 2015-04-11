<<<<<<< HEAD
aliada.dialogs.email_already_exists = function(email) {
  // Preload template
  var email_exists_template = _.template($('#email_already_exists_template').html());

  vex.open({
    content: email_exists_template({
      email: email
    }),
    showCloseButton: true,
    escapeButtonCloses: true,
    overlayClosesOnClick: true,
    contentClassName: 'email_already_exists',
    afterOpen: function() {
      $('#try-another-email-button').click(function() {
        var dialog = $(this).parents('.vex-content').data().vex;

        vex.close(dialog.id);

        $('#service_user_attributes_email').select();
      });
    }
  });
};

aliada.dialogs.postal_code_number_missing = function(postal_code_number) {
  // Preload template
  var postal_code_number_missing_template = _.template($('#postal_code_number_missing_template').html());

  vex.open({
    content: postal_code_number_missing_template({
      postal_code_number: postal_code_number
    }),
    showCloseButton: false,
    escapeButtonCloses: false,
    overlayClosesOnClick: false,
    contentClassName: 'postal_code_missing',
    afterOpen: function() {
      $('#try-another-postal-code-button').click(function() {
        var dialog = $(this).parents('.vex-content').data().vex;

        vex.close(dialog.id);

        $('#service_address_attributes_postal_code').select();
      })
    }
  });
};

aliada.dialogs.platform_error = function(error) {
  var platform_error_template = _.template($('#platform_error_template').html());
  log('platform_error ', error)

  vex.open({
    content: platform_error_template({
      error: error
    }),
    contentClassName: 'error',
  });
};

aliada.dialogs.conekta_error = function(error) {
  var conekta_error_template = _.template($('#conekta_error_template').html());

  vex.open({
    content: conekta_error_template({
      error: error
    }),
    contentClassName: 'error',
  });
};

aliada.dialogs.invalid_service = function(error) {
  var invalida_service_template = _.template($('#invalid_service_template').html());

  vex.open({
    content: invalida_service_template({
      error: error
    }),
    contentClassName: 'error',
  });
};

aliada.dialogs.succesfull_service_changes = function(next_path) {
  // Preload template
  var update_success_template = _.template($('#update_service_success_template').html());

  vex.open({
    content: update_success_template({}),
    showCloseButton: false,
    escapeButtonCloses: false,
    overlayClosesOnClick: false,
    contentClassName: 'update_success_dialog',
    afterOpen: function() {
      window.setTimeout(function(){
        redirect_to(next_path);
      }, 3000);
    },
  });
};

aliada.dialogs.confirm_service_cancel = function() {
  var cancel_one_time_service_template = _.template($('#cancel_one_time_service_template').html());

  return new Promise(function(resolve, reject) {
    vex.dialog.confirm({
      message: cancel_one_time_service_template({}),
      callback: function(value) {
        if (value == true) {
          resolve(value);
        }
      },
      buttons: [
        $.extend({}, vex.dialog.buttons.YES, {
          text: 'Si',
          className: 'action-button-gray size-extra-small vex-dialog-ok-button'
        }), $.extend({}, vex.dialog.buttons.NO, {
          text: 'No',
          className: 'action-button-pink size-extra-small vex-dialog-cancel-button',
        })
      ],
    });
  })
};

aliada.dialogs.confirm_recurrent_service_change = function() {
  var confirm_recurrent_service_change_template  = _.template($('#confirm_recurrent_service_change_template').html());

  return new Promise(function(resolve, reject) {
    vex.dialog.confirm({
      message: confirm_recurrent_service_change_template  ({}),
      callback: function(value) {
        if (value == true) {
          resolve(value);
        }
      },
      buttons: [
        $.extend({}, vex.dialog.buttons.YES, {
          text: 'Si',
          className: 'action-button-gray size-extra-small vex-dialog-ok-button'
        }), $.extend({}, vex.dialog.buttons.NO, {
          text: 'No',
          className: 'action-button-pink size-extra-small vex-dialog-cancel-button',
        })
      ],
    });
  })
}

aliada.dialogs.confirm_change_card = function() {
  var confirm_change_card = _.template($('#confirm_change_card_template').html());

  return new Promise(function(resolve, reject) {
    vex.dialog.confirm({
      message: confirm_change_card({}),
      callback: function(value) {
        if (value == true) {
          resolve(value);
        } else {
          reject();
        }
      },
      buttons: [
        $.extend({}, vex.dialog.buttons.YES, {
          text: 'Si',
          className: 'action-button-gray size-extra-small vex-dialog-ok-button'
        }), $.extend({}, vex.dialog.buttons.NO, {
          text: 'No',
          className: 'action-button-pink size-extra-small vex-dialog-cancel-button',
        })
      ],
    });
  })
}

aliada.dialogs.succesful_card_change = function(next_path) {
  // Preload template
  var succesful_card_change_template = _.template($('#succesful_card_change_template').html());

  vex.open({
    content: succesful_card_change_template({}),
  });
};

||||||| merged common ancestors
=======
aliada.dialogs.email_already_exists = function(email) {
  // Preload template
  var email_exists_template = _.template($('#email_already_exists_template').html());

  vex.open({
    content: email_exists_template({
      email: email
    }),
    showCloseButton: true,
    escapeButtonCloses: true,
    overlayClosesOnClick: true,
    contentClassName: 'email_already_exists',
    afterOpen: function() {
      $('#try-another-email-button').click(function() {
        var dialog = $(this).parents('.vex-content').data().vex;

        vex.close(dialog.id);

        $('#service_user_attributes_email').select();
      });
    }
  });
};

aliada.dialogs.postal_code_number_missing = function(postal_code_number) {
  // Preload template
  var postal_code_number_missing_template = _.template($('#postal_code_number_missing_template').html());

  vex.open({
    content: postal_code_number_missing_template({
      postal_code_number: postal_code_number
    }),
    showCloseButton: false,
    escapeButtonCloses: false,
    overlayClosesOnClick: false,
    contentClassName: 'postal_code_missing',
    afterOpen: function() {
      $('#try-another-postal-code-button').click(function() {
        var dialog = $(this).parents('.vex-content').data().vex;

        vex.close(dialog.id);

        $('#service_address_attributes_postal_code').select();
      })
    }
  });
};

aliada.dialogs.platform_error = function(error) {
  var platform_error_template = _.template($('#platform_error_template').html());
  log('platform_error ', error)

  vex.open({
    content: platform_error_template({
      error: error
    }),
    contentClassName: 'error',
  });
};

aliada.dialogs.conekta_error = function(error) {
  var conekta_error_template = _.template($('#conekta_error_template').html());

  vex.open({
    content: conekta_error_template({
      error: error
    }),
    contentClassName: 'error',
  });
};

aliada.dialogs.invalid_service = function(error) {
  var invalida_service_template = _.template($('#invalid_service_template').html());

  vex.open({
    content: invalida_service_template({
      error: error
    }),
    contentClassName: 'error',
  });
};

aliada.dialogs.succesfull_service_changes = function(next_path) {
  // Preload template
  var update_success_template = _.template($('#update_service_success_template').html());

  vex.open({
    content: update_success_template({}),
    showCloseButton: false,
    escapeButtonCloses: false,
    overlayClosesOnClick: false,
    contentClassName: 'update_success_dialog',
    afterOpen: function() {
      window.setTimeout(function(){
        redirect_to(next_path);
      }, 3000);
    },
  });
};

aliada.dialogs.confirm_service_cancel = function() {
  var cancel_one_time_service_template = _.template($('#cancel_one_time_service_template').html());

  return new Promise(function(resolve, reject) {
    vex.dialog.confirm({
      message: cancel_one_time_service_template({}),
      callback: function(value) {
        if (value == true) {
          resolve(value);
        }
      },
      buttons: [
        $.extend({}, vex.dialog.buttons.YES, {
          text: 'Si',
          className: 'action-button-gray size-extra-small vex-dialog-ok-button'
        }), $.extend({}, vex.dialog.buttons.NO, {
          text: 'No',
          className: 'action-button-pink size-extra-small vex-dialog-cancel-button',
        })
      ],
    });
  })
};

aliada.dialogs.confirm_recurrent_service_change = function() {
  var confirm_recurrent_service_change_template  = _.template($('#confirm_recurrent_service_change_template').html());

  return new Promise(function(resolve, reject) {
    vex.dialog.confirm({
      message: confirm_recurrent_service_change_template  ({}),
      callback: function(value) {
        if (value == true) {
          resolve(value);
        }
      },
      buttons: [
        $.extend({}, vex.dialog.buttons.YES, {
          text: 'Si',
          className: 'action-button-gray size-extra-small vex-dialog-ok-button'
        }), $.extend({}, vex.dialog.buttons.NO, {
          text: 'No',
          className: 'action-button-pink size-extra-small vex-dialog-cancel-button',
        })
      ],
    });
  })
}
>>>>>>> master

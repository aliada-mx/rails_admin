aliada.dialogs.email_already_exists = function(email){
    // Preload template
    var email_exists_template = _.template($('#email_already_exists').html());

    vex.open({
        content: email_exists_template({email: email}),
        showCloseButton: false,
        escapeButtonCloses: false,
        overlayClosesOnClick: false,
        contentClassName: 'email_already_exists',
        afterOpen: function(){
            $('#try-another-email-button').click(function(){
                var dialog = $(this).parents('.vex-content').data().vex;

                vex.close(dialog.id);

                $('#service_user_attributes_email').select();
            });
        }
    });  
};

aliada.dialogs.postal_code_missing = function(postal_code){
    // Preload template
    var postal_code_missing_template = _.template($('#postal_code_missing').html());

    vex.open({
        content: postal_code_missing_template({postal_code: postal_code}),
        showCloseButton: false,
        escapeButtonCloses: false,
        overlayClosesOnClick: false,
        contentClassName: 'postal_code_missing',
        afterOpen: function(){
            $('#try-another-postal-code-button').click(function(){
                var dialog = $(this).parents('.vex-content').data().vex;

                vex.close(dialog.id);

                $('#service_address_attributes_postal_code').select();
            })
        }
    });  
};

aliada.dialogs.platform_error = function(){
};

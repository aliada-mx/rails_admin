//= require modules/dialogs
//= require base
//= require jquery.tablesorter.js

$(function(){
  $('.table').tablesorter();

  $('.score_service input[type=radio]').click(function(){
    var $form = $(this).parent('form');
    var value = $(this).val();

    disableForm($form, value);

    $form.ajaxSubmit({
      dataType: 'json',
      error:  function(response){
        aliada.dialogs.platform_error(response.responseText);
      }
    });
  });

  disableForm = function(form, value){
    form.children('.unchecked').each(function(){
      $(this).toggleClass('unchecked');
      // selected, submitted value
      if (value==this.value){
        $(this).toggleClass('checked');
      }else{
        $(this).toggleClass('disabled');
      }
      $(this).prop("onclick", null);
    });

  };

});

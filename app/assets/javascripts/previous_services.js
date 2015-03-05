//= require base
//= require modules/dialogs

$(function(){

  submitRating = function(service_id, value){
    var form = $('#service_'+service_id);
    form.ajaxSubmit({
      dataType: 'json',
      error:  function(response){
        aliada.dialogs.platform_error(response.responseText);
      }
    });
    disableForm(form, value);
    return false;
  }

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
    })

  };

});

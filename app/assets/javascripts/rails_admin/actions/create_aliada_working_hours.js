$(function(){

  var activatedRecurrences = new Array();
  var disabledRecurrences = new Array();
  var newRecurrences = new Array();
  var aliada_id = $(".aliada-working-hours")[0].id;

  // Base functions
  add_csrf_token = function(xhr) {
    xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
  }

  function redirect_to(url){
    window.location.replace(url);
  }

  saveRecurrences = function(){
    // Activate
    $(".inactive-recurrence:checkbox:checked").each(function(){
      var weekday = this.id.split("_")[0];
      var hour = parseInt(this.id.split("_")[1]);
      var recurrence = {
        hour: hour,
        weekday: weekday
      }
      activatedRecurrences.push(recurrence); 
    });

    // Deactivate
    $(".active-recurrence:checkbox:not(:checked)").each(function(){
      var weekday = this.id.split("_")[0];
      var hour = parseInt(this.id.split("_")[1]);
      var recurrence = {
        hour: hour,
        weekday: weekday
      }
      disabledRecurrences.push(recurrence);
    });

    // Create
    $(".new-recurrence:checkbox:checked").each(function(){
      var weekday = this.id.split("_")[0];
      var hour = parseInt(this.id.split("_")[1]);
      var recurrence = {
        hour: hour,
        weekday: weekday
      }
      newRecurrences.push(recurrence);
    });
 
    $.ajax("create_aliada_working_hours", {
      method: "POST",
      dataType: "json",
      contentType: 'application/json',
      beforeSend: add_csrf_token,
      data: JSON.stringify({"recurrences": {
        activated_recurrences: activatedRecurrences,
        disabled_recurrences: disabledRecurrences,
        new_recurrences: newRecurrences
      }})
    }).done(function(response){
      redirect_to(response.url);
    }).fail(function(response){
      console.log(response);
      alert("Operation failed.");
    });

  };

});

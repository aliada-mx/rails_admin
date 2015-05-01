$(function(){
  // Quick adding billable hours 
  $('body').on('change', '.billable_hours_input', function(e){
    var $input = $(this);
    var $container = $(this).parent('.rails_admin_billable_hours_widget');
    var $amount_to_bill = $container.find('.amount_to_bill .amount')
    
    var path = $container.find('.update_path').data().updatepath;

    $.ajax({
      url: path,
      data: {value:  $input.val() },
      dataType: 'json',
      type: 'POST',
      success: function(response){
        $amount_to_bill.html(response.object.amount_to_bill);
      },
      error: function(e){
        alert('Hubo un error al guardar el servicio');
      },
    })
  });
});

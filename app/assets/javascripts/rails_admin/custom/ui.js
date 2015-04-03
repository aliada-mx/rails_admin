$(function(){
  $('body').on('change', '.billable_hours_input', function(e){
    var $input = $(this);
    var $container = $(this).parent('.rails_admin_billable_hours_widget');
    var $amount_to_bill = $container.find('.amount_to_bill .amount')
    
    var submit_data = {
      attribute_name: $container.find('.attribute_name').data().attributename,
      return_attribute: $container.find('.return_attribute').data().returnattribute,
      value: $input.val(),
    }

    var path = $container.find('.update_path').data().updatepath;

    $.ajax({
      url: path,
      data: submit_data,
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

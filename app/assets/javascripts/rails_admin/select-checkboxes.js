$(function() {
  bind_selectable = function() {
    $('tbody').selectable({
      filter: 'input',
      distance: 1,
      selected: function(event, ui) {
        $element = $(ui.selected)

        if ($element.is(':checkbox')) {
          $element.click();
        }
        return true;
      }
    });
  }
  bind_selectable()

  $(document).on('pjax:end', bind_selectable)
});

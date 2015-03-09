// Set the observable($object.data('observable_name'))
// Asuming the observable and the data have the same name
ko.bindingHandlers.from_data = {
    'init': function(element, valueAccessor, allBindings, viewModel) {
        var args = ko.utils.unwrapObservable(valueAccessor());
        
        var observable_name = args;
        var observable = viewModel[observable_name];

        $(element).on('change',function(e){
            // Haml converts underscores to hypens for data attributes
            var hypenated_observable_name = observable_name.replace('_','-');

            var value = $(element).data(hypenated_observable_name);
            observable(value);
        });
    }
};

// Underscore dependant version of the text binding that supports string interpolation {{ }}
// it will the viewmodel observables to get the value
ko.bindingHandlers['text_'] = {
  'init': function() {
      // Prevent binding on the dynamically-injected text node (as developers are unlikely to expect that, and it has security implications).
      // It should also make things faster, as we no longer have to consider whether the text node might be bindable.
      return { 'controlsDescendantBindings': true };
  },
  'update': function (element, valueAccessor, allBindings, viewModel) {
      var text = ko.utils.unwrapObservable(valueAccessor());

      var observables_names = _(text.match(/{{\s*[\w\.]+\s*}}/g)).map(function(x) { return x.match(/[\w\.]+/)[0]; });

      var template_variables = _.reduce(observables_names, function(variables, observable_name){
        var value = viewModel[observable_name]();
        
        variables[observable_name] = value;
        return variables;
      }, {});

      var interpolated_text = _.template(text)(template_variables)

      element.innerHTML = interpolated_text;
  }
}
ko.virtualElements.allowedBindings['text_'] = true;

// Cache a default value for observables
ko.extenders.default_value = function(target, option) {
    target.default_value = option;
    // Initialize it with default
    target(target() || target.default_value);

    target.default = function(){
      target(target.default_value);
      };

    target.is_default = function(){
      return target() === target.default_value;
      };

    target.is_not_default = function(){
        return !target.is_default();
    };

    return target;
};

ko.bindingHandlers.from_data = {
    init: function(element, valueAccessor, allBindings, viewModel) {
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

module RailsAdmin
  module Config
    module Actions
      class Export < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :controller do
          proc do
            if (format = params[:json] && :json || params[:csv] && :csv || params[:xml] && :xml)
              config = ActiveRecord::Base.remove_connection
              pid = fork do
                begin
                  ActiveRecord::Base.establish_connection(config)
                  @schema = params[:schema].symbolize if params[:schema] # to_json and to_xml expect symbols for keys AND values.
                  @objects = list_entries(@model_config, :export)

                  case format
                  when :json
                    attachment_data = @objects.to_json(@schema)
                  when :xml
                    attachment_data = @objects.to_xml(@schema)
                  when :csv
                    _, _, attachment_data = CSVConverter.new(@objects, @schema).to_csv(params[:csv_options])
                  end

                  attachment_filename = "#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.#{format}"
                  ExportMailer.results_email(current_user, attachment_filename, attachment_data).deliver_now
                ensure
                  ActiveRecord::Base.remove_connection
                  Process.exit!(0)
                end
              end
              Process.detach(pid)
              ActiveRecord::Base.establish_connection(config)
              redirect_to index_path
            else
              render @action.template_name
            end
          end
        end

        register_instance_option :bulkable? do
          true
        end

        register_instance_option :link_icon do
          'icon-share'
        end
      end
    end
  end
end

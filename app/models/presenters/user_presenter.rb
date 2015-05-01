# -*- encoding : utf-8 -*-
module Presenters
  module UserPresenter

    def role_enum
      User::ROLES.map{ |role| [ role[1],role[0] ] }
    end

    # TODO use actual user chosen address
    def default_address
      addresses.first
    end

    def default_address_link
      rails_admin_edit_link( default_address ) if default_address
    end

    def next_service_link
      rails_admin_edit_link( next_service ) if next_service
    end

    def name
      return full_name if full_name.present?

      return "#{first_name} #{last_name}" if first_name.present? || last_name.present?
      email
    end

    def contact_data
      "#{name}, #{email}, #{phone}"
    end

    def next_service
      services.in_the_future.first
    end

    def payment_provider_name
      default_payment_provider.friendly_name
    end

    def payment_provider_choices_list
      list = ' '
      payment_provider_choices.each do |choice|
        list += "#{choice.provider.name}, "
      end
      # Remove the trailing comma
      list.strip![0..-2]
    end

    def postal_code_number
      if default_address
        default_address.postal_code.number
      end
    end

    def error_messages
      errors.messages.map do |field, message|
        "#{message.first}"
      end.join(',')
    end

    def user_next_services_path
      Rails.application.routes.url_helpers.next_services_users_path(self) if self.persisted?
    end

    def last_login
      if last_sign_in_at
        I18n.l(last_sign_in_at, format: :future)
      else
        I18n.l(created_at, format: :future)
      end
    end

    def list_points_history
      versions.select do |version|
        version.changeset.has_key?('balance')
      end
    end

    def list_balance_changes
      string = list_points_history.collect do |version|
        whodunnit = User.find(version.whodunnit) if version.whodunnit
        "era: #{ version.changeset['balance'].first } es: #{ version.changeset['balance'].last } #{whodunnit.name}" if version.changeset['balance']
      end.join(', ')
      string
    end
  end
end

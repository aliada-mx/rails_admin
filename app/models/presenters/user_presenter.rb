module Presenters
  module UserPresenter

    def role_enum
      User::ROLES.map{ |role| [ role[1],role[0] ] }
    end

    # TODO use actual user chosen address
    def default_address
      addresses.first
    end

    def name
      return "#{first_name} #{last_name}" if first_name.present? || last_name.present?
      email
    end

    def next_service
      services.in_the_future.first
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
      default_address.postal_code.number
    end
  end
end

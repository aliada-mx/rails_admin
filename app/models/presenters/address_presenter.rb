module Presenters
  module AddressPresenter

    def name
      "#{street} #{number} int. #{interior_number} #{colony}"
    end

    def to_json
      self.attributes.merge({name: name,
                             postal_code_number: postal_code.number}).to_json
    end
  end
end

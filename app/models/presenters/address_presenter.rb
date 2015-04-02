module Presenters
  module AddressPresenter

    def name
      "#{street} #{number} int. #{interior_number} #{colony}"
    end

    def to_json
      attributes = self.attributes

      attributes.merge!( {name: name, postal_code_number: postal_code.number} )
      attributes.merge!( {latitude: 19.4375428, longitude: -99.1482577} ) if map_missing?

      attributes.to_json
    end
  end
end

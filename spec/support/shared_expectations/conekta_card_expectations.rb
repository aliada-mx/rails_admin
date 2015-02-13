module TestingSupport
  module SharedExpectations
    module ConektaCardExpectations
      def expects_it_to_be_complete_and_valid(card)
        expect(card.name).to eql "Jorge Lopez"
        expect(card.last4).to eql "4242"
        expect(card.exp_month).to eql "12"
        expect(card.exp_year).to eql "19"
        expect(card.active).to be true
      end
    end
  end
end




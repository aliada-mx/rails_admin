# -*- encoding : utf-8 -*-
describe 'User' do
  let(:starting_datetime) { Time.zone.parse('01 Jan 2015 16:00:00') }
  let!(:conekta_card){ create(:conekta_card) }
  let!(:user){ create(:user) }
  let!(:aliada){ create(:aliada) }
  let!(:other_aliada){ create(:aliada) }
  let!(:service){ create(:service, 
                         aliada: aliada,
                         user: user,
                         datetime: starting_datetime,
                         aliada_reported_begin_time: Time.zone.now,
                         aliada_reported_end_time: Time.zone.now + 3.hours) }
  let!(:other_service){ create(:service, 
                               aliada: other_aliada,
                               user: user,
                               datetime: starting_datetime) }
  let!(:other_conekta_card){ create(:conekta_card) }

  describe '#past_aliadas' do

    before do
      Timecop.freeze(starting_datetime + 1.hour)
    end

    after do
      Timecop.return
    end

    it 'returns the aliadas on the user services' do
      expect(user.past_aliadas).to eql [aliada, other_aliada]
    end
  end

  describe '#create_payment_provider_choice' do
    it 'sets the default payment provider to the last created' do
      user.create_payment_provider_choice(conekta_card)

      expect(user.default_payment_provider).to eql conekta_card

      user.create_payment_provider_choice(other_conekta_card)

      expect(user.default_payment_provider).to eql other_conekta_card
    end 
  end

  describe '#charge_points' do
    context 'charging with enough user points' do
      before do
        user.points = 200
        @amount = 200
      end

      it 'reduces the user points for the amount' do
        user.charge_points(@amount, service)

        expect(user.points).to eql 0
      end

      it 'creates a payment for the amount reduced' do
        credits_charger = user.charge_points(@amount, service)

        payment = credits_charger.payment

        expect(payment.class).to be Payment
        expect(payment.amount).to eql 200
      end
    end

    context 'charging without enough user points' do
      before do
        user.points = 0

        user.create_payment_provider_choice(conekta_card)
      end

      it 'leaves the user points the same' do
        payment = user.charge_points(300, service)

        expect(payment.left_to_charge).to eql 300
        expect(Payment.count).to be 0
      end
    end
  end

  describe '#register_debt' do
    before do
      user.create_payment_provider_choice(conekta_card)
    end

    it 'reduces the points by the passed amount' do
      product = OpenStruct.new({amount: 100, 
                                category: 'service'})
      user.register_debt(product, service)

      expect(user.balance).to eql( -100 )
    end

    it 'should only register one debt per service' do
      product = OpenStruct.new({amount: 100, 
                                category: 'service'})
      user.register_debt(product, service)
      user.register_debt(product, service)

      expect(user.debts.count).to be 1
    end
  end

  describe 'charge!' do
    context 'with a service that cost more than the current points' do
      before do
        user.points = 100
        user.save!
        @product = OpenStruct.new({amount: 300,
                                   category: 'service'})
        user.create_payment_provider_choice(conekta_card)
      end

      context 'with the default_payment_provider failing' do
        before do
          allow_any_instance_of(ConektaCard).to receive(:charge!).and_return(nil)
        end

        it 'leaves the user points negative' do
          
          user.charge!(@product, service)

          expect(user.balance).to eql( -200 )
          expect(Debt.all.count).to eql(1)
          debt = Debt.first
          expect(debt.amount).to eql 200
          expect(debt.service).to eql service
          expect(debt.user).to eql user
          expect(debt.payment_provider_choice.provider).to eql conekta_card
          expect(debt.category).to eql 'service'
        end
      end

      context 'with the default_payment_provider succesfully charging' do
         
        it 'only charges the amount reduced by the points' do
          @product.amount = 200
          allow_any_instance_of(ConektaCard).to receive(:charge!).with(@product, user, service)

          user.charge!(@product, service)
        end
      end
    end
  end
end

# -*- encoding : utf-8 -*-
# -*- coding: utf-8 -*-
feature 'UserController' do
  let!(:conekta_card){ create(:conekta_card)}
  let!(:user){ create(:user, password: '12345678',
                             first_name: 'Juan',
                             last_name: 'Perez',
                             phone: '6666',
                             email: 'juan@perez.com')}
    
  describe '#edit' do
    before do
      login_as(user)

      allow_any_instance_of(User).to receive(:default_payment_provider).and_return(conekta_card)

      visit edit_users_path user
    end

    it 'lets the user change all its attributes without changing the password' do
      fill_in 'user_first_name', with: 'Guillermo'
      fill_in 'user_last_name', with: 'Siliceo'
      fill_in 'user_phone', with: '9392923983'
      fill_in 'user_email', with: 'prueba@aliada.mx'

      click_button 'Guardar'

      user.reload
      expect(user.first_name).to eql 'Guillermo'
      expect(user.last_name).to eql 'Siliceo'
      expect(user.phone).to eql '9392923983'
      expect(user.email).to eql 'prueba@aliada.mx'
    end

    it 'lets the user change its password' do
      previous_password = user.encrypted_password

      fill_in 'user_password', with: '0987654321'
      fill_in 'user_password_confirmation', with: '0987654321'

      click_button 'Guardar'

      user.reload
      expect(user.encrypted_password).to_not eql previous_password
    end
  end
end


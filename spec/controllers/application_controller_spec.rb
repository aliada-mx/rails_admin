feature 'ApplicationController' do
  include TestingSupport::ServiceControllerHelper
  starting_datetime = Time.zone.now.change({hour: 13})
  let!(:conekta_card){ create(:payment_method)}
  let!(:extra_1){ create(:extra, name: 'Lavanderia')}
  let!(:one_time_service) { create(:service_type, name: 'one-time') }
  let!(:zone) { create(:zone) }
  let!(:postal_code) { create(:postal_code, 
                              :zoned, 
                              zone: zone,
                              code: '11800') }

  context 'when creating a service without a conekta token' do

    before do
      @default_capybara_ignore_hidden_elements_value = Capybara.ignore_hidden_elements
      Capybara.ignore_hidden_elements = false
    end

    after do
      Capybara.ignore_hidden_elements = @default_capybara_ignore_hidden_elements_value
    end

    it 'catches the exception and renders a json error' do
      visit initial_service_path

      fill_service_form(conekta_card, one_time_service, starting_datetime, extra_1, zone)

      VCR.use_cassette('initial_service_conekta_card_without_token') do
        click_button 'Confirmar visita'
      end

      expect(page).to have_content '{"status":"error","sender":"conekta","messages":["El recurso no ha sido encontrado."]}'
    end
  end
end

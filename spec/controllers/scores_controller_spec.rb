# -*- encoding : utf-8 -*-
feature 'ScoresController' do
  include TestingSupport::SchedulesHelper
  
  let(:starting_datetime) { Time.zone.parse('02 Jan 2015 13:00:00') }
  let(:service_datetime) { Time.zone.parse('01 Jan 2015 13:00:00') }
  let(:aliada){ create(:aliada) }
  let!(:user){ create(:user) } 
  let!(:other_user){ create(:user) } 
  let!(:service){ create(:service, aliada: aliada, user: user, datetime: service_datetime) }
  let!(:admin){ create(:admin) }
 
  before do
    Timecop.freeze(starting_datetime)
  end

  after do
    Timecop.return
  end

  context 'rate aliadas services' do

    it 'returns a json with a correct score object' do
      login_as(user)

      with_rack_test_driver do
        page.driver.submit :post, score_service_users_path(user, service), {value: 3.0}
      end
      
      response = JSON.parse(page.body)["score"]

      expect(Score.count).to be 1
      expect(response["service_id"]).to be service.id
      expect(response["value"]).to eq "3.0"
      expect(response["user_id"]).to be service.user_id
      expect(response["aliada_id"]).to be service.aliada_id
    end

    it 'allows it to score again' do
      login_as(user)

      with_rack_test_driver do
        page.driver.submit :post, score_service_users_path(user, service), {value: 3.0}
        page.driver.submit :post, score_service_users_path(user, service), {value: 3.0}
      end

      expect(page.status_code).to be 200
      expect(Score.count).to be 2
    end

    it 'should create a rating as an admin' do

      login_as(admin)

      with_rack_test_driver do
        page.driver.submit :post, score_service_users_path(user, service), {value: 3.0}
      end
      
      response = JSON.parse(page.body)["score"]

      expect(Score.count).to be 1
      expect(response["service_id"]).to be service.id
      expect(response["value"]).to eq "3.0"
      expect(response["user_id"]).to be service.user_id
      expect(response["aliada_id"]).to be service.aliada_id

    end

    it 'should not create score if a rating tries to be created as another user' do
      login_as(other_user)

      with_rack_test_driver do
        page.driver.submit :post, score_service_users_path(user, service), {value: 3.0}
      end

      expect(Score.count).to be 0
    end

  end

end

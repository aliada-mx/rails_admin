# -*- encoding : utf-8 -*-
# -*- coding: utf-8 -*-
feature 'RailsAdminCustomActionController' do
  let!(:admin){ create(:admin) }
  let!(:service){ create(:service, billable_hours: 3) }
    
  describe '#add_billable_hours_to_service' do
    before do
      @params = {
        value: '4',
      }
      @update_object_path = Rails.application.routes.url_helpers.add_billable_hours_to_service_path(service.id)
      clear_session
    end
    
    after do
      clear_session
    end

    it 'doesnt let a non admin update a service' do
      with_rack_test_driver do
        page.driver.submit :post, @update_object_path, @params
      end

      expect(service.billable_hours).to eql 3
    end

    it 'lets a admin to update a service' do
      login_as(admin)

      with_rack_test_driver do
        page.driver.submit :post, @update_object_path, @params
      end

      service.reload
      expect(service.billable_hours).to eql 4
      expect(service).to be_finished
    end
  end
end


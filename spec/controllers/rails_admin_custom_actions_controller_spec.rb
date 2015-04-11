# -*- encoding : utf-8 -*-
# -*- coding: utf-8 -*-
feature 'RailsAdminCustomActionController' do
  let!(:admin){ create(:admin) }
  let!(:service){ create(:service, billable_hours: 3) }
    
  describe '#update_object_attribute' do
    before do
      @params = {
        attribute_name: 'billable_hours',
        value: '4',
      }
      @update_object_path = Rails.application.routes.url_helpers.update_object_attribute_path('Service', service.id)
      clear_session
    end
    
    after do
      clear_session
    end

    it 'doesnt let a non admin update an object' do
      with_rack_test_driver do
        page.driver.submit :post, @update_object_path, @params
      end

      expect(service.billable_hours).to eql 3
    end

    it 'lets a admin to update an object attribute' do
      login_as(admin)

      with_rack_test_driver do
        page.driver.submit :post, @update_object_path, @params
      end

      expect(service.reload.billable_hours).to eql 4
    end
  end
end


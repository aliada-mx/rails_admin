class IncompleteService < ActiveRecord::Base
  belongs_to :service
  belongs_to :service_type

  def self.mark_as_complete(params, service)
    incomplete_service = IncompleteService.find(params[:id])
    incomplete_service.service = service
    incomplete_service.save!
  end
end

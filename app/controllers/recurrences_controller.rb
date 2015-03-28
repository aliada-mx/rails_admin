class RecurrencesController < ApplicationController
  layout 'one_column', only: :show

  def show
    @recurrence = Recurrence.find(params[:recurrence_id])
    @base_service = @recurrence.base_service
    @services = @recurrence.services.ordered_by_datetime.in_the_future.select { |service| service.one_timer? }
  end
end

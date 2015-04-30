# -*- encoding : utf-8 -*-
class AliadaChooser
  attr_reader :aliadas_availability, :aliadas
  # Encasulates the aliada choosing algorithm
   
  # Receives the result of AvailabilityForService.find
  # returns an aliada availability
  def initialize(aliadas_availability, service)
    @aliadas_availability = aliadas_availability  
    @service = service
  end

  def choose!
    load_aliadas
    sort_aliadas
    first
  end

  def self.choose_availability(aliadas_availability, service)
    AliadaChooser.new(aliadas_availability, service).choose!
  end

  private
    def first
      aliada = @aliadas.first
      @aliadas_availability.for_aliada(aliada)
    end

    def load_aliadas
      aliadas_ids = @aliadas_availability.aliadas_ids
      @aliadas = Aliada.for_booking(aliadas_ids).to_a
    end

    def sort_aliadas
      @aliadas.sort_by! { |aliada| [Invert(aliada.busy_services_hours), 
                                    aliada.closeness_to_service(@service),
                                    aliada.average_score,
                                    Invert(aliada.created_at)] }.reverse!
    end

end

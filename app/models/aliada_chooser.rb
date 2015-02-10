class AliadaChooser
  attr_reader :aliadas_availability, :aliadas
  # Encasulates the aliada choosing algorithm
   
  # Receives the result of ScheduleChecker.match_schedules
  # returns an aliada availability
  def initialize(aliadas_availability, service)
    @aliadas_availability = aliadas_availability  
    @service = service

    @user_past_aliadas_ids = service.user.past_aliadas.map(&:id)
  end

  def choose!
    load_aliadas
    sort_candidates
    first
  end

  def self.find_aliada_availability(aliadas_availability, service)
    AliadaChooser.new(aliadas_availability, service).choose!
  end

  private
    def first
      aliada = @aliadas.first
      @aliadas_availability.for_aliada(aliada)
    end

    def load_aliadas
      aliadas_ids = @aliadas_availability.ids
      @aliadas = Aliada.for_booking(aliadas_ids).to_a
    end

    def sort_candidates
      @aliadas.sort_by! { |aliada| [Invert(aliada.busy_services_hours), 
                                    aliada.closeness_to_service(@service),
                                    aliada.average_score,
                                    Invert(aliada.created_at)] }.reverse!
    end

end

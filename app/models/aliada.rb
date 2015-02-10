class Aliada < User
  include AliadaSupport::AliadasHelpers

  has_many :aliada_zones
  has_many :zones, through: :aliada_zones

  has_many :schedules, foreign_key: :aliada_id
  has_many :scores, foreign_key: :aliada_id
  has_many :services, foreign_key: :aliada_id
  has_many :addresses, foreign_key: :aliada_id
  has_and_belongs_to_many :banned_users,
                          class_name: 'User',
                          join_table: :banned_aliada_users,
                          foreing_key: :user_id,
                          association_foreign_key: :aliada_id

  # TODO optimize to get all aliadas even those without services but the ones with services 
  # must have services.datetime >= Time.zone.now.beginning_of_day
  scope :for_booking, ->(aliadas_ids) { where(id: aliadas_ids).eager_load(:services) }

  default_scope { where('users.role = ?', 'aliada') }

  # Return the last service an aliada has before the one we are passing
  # on the same day
  def previous_service(current_service)
    services.to_a.select{ |service| service.datetime >= current_service.datetime.beginning_of_day }
                 .select{ |service| service.datetime < current_service.datetime }
                 .sort_by(&:created_at)
                 .last
  end

  # TODO use real physical closeness 
  def closeness_to_service(service)
    closest_service = previous_service(service)

    return 0 unless service.present? and closest_service.present?

    service.zone == closest_service.zone ? 1 : 0
  end

  def average_score
    scores.average(:value)
  end

  def services_on_day(datetime)
    services.on_day(datetime)
  end

  # Count the number of projected working hours until our time horizon
  # in the future
  def service_hours
    now = Time.zone.now
    services.to_a.select{ |service| service.datetime >= now }.inject(0) { |sum, service| sum += service.total_hours }
  end

  def busy_services_hours
    businesshours_until_horizon - service_hours
  end
end

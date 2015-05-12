# -*- encoding : utf-8 -*-
class Aliada < User
  include AliadaSupport::DatetimeSupport
  include Mixins::RailsAdminModelsHelpers
  include Presenters::AliadaPresenter

  has_many :aliada_zones
  has_many :zones, through: :aliada_zones
  has_many :documents, inverse_of: :aliada, foreign_key: :user_id

  has_many :recurrences
  has_many :aliada_working_hours
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
  scope :for_booking, ->(aliadas_ids) {where(id: aliadas_ids).eager_load(:services).eager_load(:zones)}
  # For rails admin
  #
  scope :todas, -> { joins('FULL OUTER JOIN scores on users.id = scores.aliada_id').group('users.id') }

  after_initialize do
    if new_record?
      self.role = 'aliada'
    end
  end

  # We override the default_scope class method so the user default scope from
  # which we inherited does not override ours
  def self.default_scope 
    where('users.role = ?', 'aliada')
  end

  def previous_service(current_service) # On the same day
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

  def gverage_score
    scores.average(:value)
  end

  def services_on_day(datetime)
    services.on_day(datetime)
  end

  # Count the number of projected working hours until our time horizon
  # in the future
  def service_hours
    now = Time.zone.now
    services.to_a.select{|service| service.datetime >= now }.inject(0) { |sum, service| sum += service.total_hours}
  end

  def busy_services_hours
    businesshours_until_horizon - service_hours
  end

  def timezone
    'Mexico City'
  end

  def current_week_services
    today = ActiveSupport::TimeZone["Mexico City"].today
    Service.where(aliada_id: self.id, :datetime => today.beginning_of_week..today.end_of_week.advance(:days => 1)).not_canceled
  end

  def current_week_reported_hours
    services = self.current_week_services
    sum = 0
    services.each do |s|
      if s.hours_worked
        sum = sum + s.hours_worked
      end
    end
    return sum
  end
  
  def aliada_webapp_link
    aliada_show_webapp_link(self)
  end

  def track_webapp_view(request)
    tracker = Mixpanel::Tracker.new(Setting.mixpanel_token)
    agent = Agent.new request.env['HTTP_USER_AGENT']

    options = { 
      'agent_name' => agent.name,
      'agent_version' => agent.version,
      'agent_engine' => agent.engine,
      'agent_os' => agent.os,
      'agent_engine_version' => agent.engine_version,
      'REMOTE_ADDR' => request.env['REMOTE_ADDR'],
      'aliada_name' => self.name,
      'environment' => Rails.env,
    }

    tracker.track(self.name, 'aliada viewed webapp', options)
  end

  rails_admin do
    label_plural 'aliadas'
    navigation_label 'Personas'
    navigation_icon 'icon-heart'
    weight -8
    # Rails admin believes that the parent is the user
    # so it adds the aliada navigation link below the user
    # by setting to Object we override that
    parent Object

    configure :name do
      virtual?
      read_only
    end

    configure :points do
      visible false
    end

    configure :sign_in_count do
      visible false
    end

    show do
      include_all_fields
    end

    list do
      search_scope do
        Proc.new do |scope, query|
          query_without_accents = I18n.transliterate(query)

          scope.merge(UnscopedUser.with_name_phone_email(query_without_accents))
        end
      end
      field :full_name

      field :phone do
        queryable false
        filterable false
      end
      field :aliada_webapp_link
      field :average_score do
        sortable "AVG(scores.value)"

        formatted_value do
          value.round(2) if value
        end
      end

      field :services_worked do
        virtual?
      end

      scopes [:todas]
    end

    edit do
      field :role do
        read_only true
      end
      field :first_name
      field :last_name
      field :email
      field :phone
      field :documents

      field :recurrences
      field :zones

      field :password do
        required false
      end
      field :password_confirmation

      group :login do
        active false
        field :current_sign_in_at
        field :sign_in_count
        field :last_sign_in_at
        field :last_sign_in_ip
        field :current_sign_in_ip
        field :remember_created_at
        field :reset_password_sent_at
      end
      exclude_fields :payment_provider_choices,
                     :schedules,
                     :aliada_zones,
                     :banned_aliadas,
                     :banned_users
    end
  end
end

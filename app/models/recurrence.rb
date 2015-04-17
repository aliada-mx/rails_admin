# -*- encoding : utf-8 -*-
class Recurrence < ActiveRecord::Base
  include AliadaSupport::DatetimeSupport
  include Mixins::RecurrenceAliadaWorkingHoursMixin
  include Mixins::ServiceRecurrenceMixin

  ATTRIBUTES_SHARED_WITH_SERVICE = 
    [:entrance_instructions, 
     :estimated_hours, 
     :hours_after_service,
     :rooms_hours,
     :address_id,
     :bathrooms,
     :bedrooms,
     :user_id,
     :zone_id,
     :time,
     :date,
     :datetime,
     :hour,
     :attention_instructions,
     :extra_ids,
     :aliada_id,
     :cleaning_supplies_instructions,
     :equipment_instructions,
     :forbidden_instructions,
     :garbage_instructions,
     :special_instructions]


  has_paper_trail

  validates_presence_of [:weekday, :hour]
  validates :weekday, inclusion: {in: Time.weekdays.map{ |days| days[0] } }
  validates :hour, inclusion: {in: [*0..23] } 
  validates_numericality_of :periodicity, greater_than: 1
  validates :status, inclusion: {in: STATUSES.map{ |pairs| pairs[1] } }

  belongs_to :user
  belongs_to :aliada
  belongs_to :zone
  has_many :services, inverse_of: :recurrence 
  has_many :schedules
  has_many :extra_recurrences
  has_many :extras, through: :extra_recurrences
  belongs_to :address

  # Scopes

  scope :ordered_by_created_at, -> { order(:created_at) }
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }

  state_machine :status, :initial => 'active' do
    transition 'active' => 'inactive', :on => :deactivate
    transition 'inactive' => 'active', :on => :activate

    after_transition on: :deactivate do |recurrence, transition|
      recurrence.services.in_the_future.each do |service|
        service.cancel
      end
    end
  end

  # Among recurrent services
  def attributes_shared_with_service 
    self.attributes.select { |key, value| ATTRIBUTES_SHARED_WITH_SERVICE.include?( key.to_sym )  }
  end

  # Cancel this service and all related through the recurrence
  def cancel_all!
    ActiveRecord::Base.transaction do
      deactivate

      charge_cancelation_fee! if should_charge_cancelation_fee
    end
  end

  def should_charge_cancelation_fee
    next_service.should_charge_cancelation_fee if next_service.present?
  end

  def charge_cancelation_fee!
    next_service.charge_cancelation_fee!
  end

  def next_service
    services.not_canceled.ordered_by_datetime.where('datetime > ?', Time.zone.now).first
  end

  def services_to_reschedule
    if datetime and rescheduling_a_recurrence_day
      services.not_canceled.in_or_after_datetime(datetime.beginning_of_aliadas_day).to_a
    else
      services.not_canceled.in_the_future.to_a
    end
  end

  def rescheduling_a_recurrence_day
    timezone_datetime.weekday == weekday
  end

  def timezone_datetime
    datetime.in_time_zone('Etc/GMT+6')
  end

  def related_services_ids
    services_to_reschedule.map { |s| s.id }
  end

  def user_modified_booking?(recurrence_params)
    self.hour            != recurrence_params[:hour] ||
    self.weekday         != recurrence_params[:weekday] ||
    self.estimated_hours != recurrence_params[:estimated_hours] ||
    self.aliada_id       != recurrence_params[:aliada_id]
  end

  def timezone
    'Etc/GMT+6' # No dst changes timezone
  end

  def name
    "#{user.first_name} #{weekday_in_spanish} de #{hour} a #{ending_hour} (#{id})"
  end

  def parse_timezone_datetime(recurrence_params)
    ActiveSupport::TimeZone[self.timezone].parse("#{recurrence_params[:date]} #{recurrence_params[:time]}")
  end

  def parse_params(recurrence_params)
    if recurrence_params['time'].present? && recurrence_params['date'].present?
      timezone_datetime = parse_timezone_datetime(recurrence_params)

      recurrence_params[:datetime] = timezone_datetime.utc
      recurrence_params[:weekday] = timezone_datetime.weekday
      recurrence_params[:hour] = timezone_datetime.hour
    else
      # On instructions changes there is no datetime set
      # TODO make sure the datetime hour and weekday is always passed by the frontend
      recurrence_params[:hour] = self.hour
      recurrence_params[:weekday] = self.weekday
    end

    recurrence_params[:estimated_hours] = BigDecimal.new(recurrence_params[:estimated_hours])
    recurrence_params[:aliada_id] = recurrence_params[:aliada_id].to_i
    
    recurrence_params
  end

  # We can't use the name 'update' because thats a builtin method
  def update_existing!(recurrence_params)
    ActiveRecord::Base.transaction do
      recurrence_params = parse_params(recurrence_params)

      chosen_aliada_id = recurrence_params[:aliada_id]

      needs_rescheduling = user_modified_booking?(recurrence_params)
      
      update_all(recurrence_params)

      reschedule!(chosen_aliada_id) if needs_rescheduling

      save_all!
    end
  end

  def update_all(new_attributes)
    self.attributes = new_attributes

    services_to_reschedule.each do |service|
      service.attributes = new_attributes
    end
  end

  def save_all!
    self.save

    services.map(&:save!)
  end

  def recurrent?
    true
  end

  def reschedule!(chosen_aliada_id)
    previous_services = services_to_reschedule
    
    aliada_availability = book(chosen_aliada_id)

    # We might have not used some or all those schedules the service had, so enable them back
    aliada_availability.enable_unused_schedules

    self.hours_after_service = aliada_availability.padding_count
    self.aliada_id = chosen_aliada_id
    self.save!

    previous_services.map(&:cancel)
  end

  def book(chosen_aliada_id)

    available_after = starting_datetime_to_book_services

    aliadas_availability = AvailabilityForService.find_aliadas_availability(self, available_after, aliada_id: chosen_aliada_id)

    raise AliadaExceptions::AvailabilityNotFound if aliadas_availability.empty?

    aliada_availability = AliadaChooser.choose_availability(aliadas_availability, self)
    self.aliada = aliada_availability.aliada
    self.save!

    aliada_availability.rebook_recurrence(self)
  end
   
  # Among recurrent services

  attr_accessor :date
  attr_accessor :time
  attr_accessor :datetime

  rails_admin do
    label_plural 'recurrencias'
    navigation_label 'Operación'
    navigation_icon 'icon-repeat'

    configure :services do
      associated_collection_scope do 
        recurrence = bindings[:object]
        if recurrence.services
          Proc.new { |scope|
            # scoping only the unused placeholders and our own placeholders
            scope.where(recurrence_id: recurrence.id)
          }
        end
      end
    end

    list do

      search_scope do
        Proc.new do |scope, query|
          query_without_accents = I18n.transliterate(query)

          scope.merge(UnscopedUser.with_name_phone_email(query_without_accents))
        end
      end

      field :user do 
        searchable [{users: :first_name }, {users: :last_name }, {users: :email}, {users: :phone}]
        queryable true
        filterable true
      end
      field :aliada
      field :name
      field :total_hours
      field :special_instructions
    end
  end
end

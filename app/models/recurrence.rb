# -*- encoding : utf-8 -*-
class Recurrence < ActiveRecord::Base
  include AliadaSupport::DatetimeSupport
  include Mixins::RecurrenceAliadaWorkingHoursMixin
  include Mixins::ServiceRecurrenceMixin

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
  end

  default_scope { where(owner: 'user') }

  attr_accessor :date
  attr_accessor :time

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

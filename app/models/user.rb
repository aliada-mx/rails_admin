# -*- encoding : utf-8 -*-
class User < ActiveRecord::Base
  #Required to enable token authentication
  acts_as_token_authenticatable

  has_paper_trail

  include Presenters::UserPresenter
  include Mixins::RailsAdminModelsHelpers
  include UsersHelper

  ROLES = [
    ['client', 'Cliente'],
    ['aliada', 'Aliada'],
    ['admin', 'Admin'],
  ]

  has_many :recurrences
  has_many :credits
  has_many :redeemed_credits, :foreign_key => "redeemer_id", :class_name => "Credit"
  has_one :code
  has_many :services, ->{ order(:datetime) }, inverse_of: :user, foreign_key: :user_id
  has_many :addresses, inverse_of: :user
  has_many :schedules, inverse_of: :user, foreign_key: :user_id
  has_and_belongs_to_many :banned_aliadas,
                          class_name: 'Aliada',
                          join_table: :banned_aliada_users,
                          foreing_key: :user_id,
                          association_foreign_key: :aliada_id

  has_many :payment_provider_choices, -> { order('payment_provider_id DESC') }, inverse_of: :user
  has_many :debts


  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  before_validation :ensure_password
  before_validation :set_default_role
  before_save :fill_full_name

  default_scope { where('users.role in (?)', ["client", "admin"]) }

  validates :role, inclusion: {in: ROLES.map{ |pairs| pairs[0] } }
  validates_presence_of :password, if: :password_required?
  validates_confirmation_of :password, if: :password_required?
  validates_length_of :password, within: Devise.password_length, allow_blank: true

  after_initialize do
    self.credits ||= 0 if self.respond_to? :credits
    self.role ||= 'client'
  end

  def fill_full_name
    self.full_name = "#{first_name.strip} #{last_name.strip}" if first_name.present? && last_name.present?
  end

  def zone
    default_address.try(:postal_code).try(:zone)
  end
  
  def create_promotional_code code_type
    if self.role == "client"
      Code.generate_unique_code self, code_type
    end
  end

  def password_required?
    !persisted? || !password.blank? || !password_confirmation.blank?
  end

  def self.email_exists?(email)
    ## Devise is configured to save emails in lower case lets search them like so
    User.find_by_email(email.strip.downcase).present?
  end

  def create_first_payment_provider!(payment_method_id)
    payment_method = PaymentMethod.find(payment_method_id)
    payment_provider = payment_method.provider_class.create!

    create_payment_provider_choice(payment_provider)
  end

  def charge_points(amount, service)
    points_charger = PointsCharger.new(amount, self, service)
    points_charger.charge!
  end

  def register_debt(product, service)
    default_payment_provider.register_debt(product,self,service)
  end

  def balance
    amount_owed.present? ? points - amount_owed : 0
  end

  def amount_owed
    total = 0
    debts.each do |debt|
      unless debt.paid?
        total += debt.amount
      end
    end
    total
  end

  def charge!(product, service)
    points_payment = charge_points(product.amount, service)

    product.amount = points_payment.left_to_charge
    begin
      payment = default_payment_provider.charge!(product, self, service)
    rescue Conekta::Error, Conekta::ProcessingError => e
      raise e
    ensure
      if payment.nil? && !service.owed?
        register_debt(product, service)
      end
    end
    payment
  end

  def create_payment_provider_choice(payment_provider)
    # Switch the default
    PaymentProviderChoice.where(user: self).update_all default: false

    # The newest is the default
    PaymentProviderChoice.create!(payment_provider: payment_provider, default: true, user: self)
  end

  def create_charge_failed_ticket(user, amount, error)
    Ticket.create_error(relevant_object: self,
                        category: 'conekta_charge_failure',
                        message: "No se pudo realizar cargo de #{amount} a la tarjeta de #{user.first_name} #{user.last_name}. #{error.message_to_purchaser}")
  end

  def default_address
    addresses.first
  end

  def create_charge_failed_ticket(user, amount, error)
    Ticket.create_error(relevant_object: self,
                        category: 'conekta_charge_failure',
                        message: "No se pudo realizar cargo de #{amount} a la tarjeta de #{user.first_name} #{user.last_name}. #{error.message_to_purchaser}")
  end

  def default_payment_provider_choice
    payment_provider_choices.default
  end

  def default_payment_provider
    default_payment_provider_choice.provider if payment_provider_choices.any?
  end

  def past_aliadas
    services.in_the_past.joins(:aliada).order('aliada_id').map(&:aliada)
  end

  def aliadas
    services.joins(:aliada).map(&:aliada).select { |aliada| !banned_aliadas.include? aliada }.uniq || []
  end
  
  def set_default_role
    self.role ||= 'client' if self.respond_to? :role
  end

  def ensure_password
    self.password ||= generate_random_pronouncable_password if self.password.blank? && self.encrypted_password.blank?
  end

  def ensure_first_payment!(payment_method_options, service)
    default_payment_provider.ensure_first_payment!(self, payment_method_options, service)
  end

  def redeem_code code_name
    code = Code.find_by(name: code_name)
    if code
      Credit.create(user_id: code.user_id, code_id: code.id, redeemer_id: self.id)
    end
  end

  def admin?
    role == 'admin'
  end

  def timezone
    'Mexico City'
  end

  def send_welcome_email
    UserMailer.welcome(self).deliver!
  end

  def send_confirmation_email(service)
    UserMailer.service_confirmation(service).deliver!
  end

  def send_service_confirmation_pwd(service, pwd)
    UserMailer.service_confirmation_pwd(service, pwd).deliver!
  end

  def send_billing_receipt(service)
    UserMailer.billing_receipt(self, service)
  end
  
  def send_payment_problem_email(payment_method)
    UserMailer.payment_problem(self, payment_method)
  end
  
  def send_address_change_email(new_address, prev_address)
    UserMailer.user_address_changed(self, new_address, prev_address)
  end

  rails_admin do
    navigation_label 'Personas'
    navigation_icon 'icon-user'
    label_plural 'usuarios'

    configure :user_next_services_path do
      read_only true
      visible do
        value.present?
      end

      formatted_value do
        view = bindings[:view]
        user = bindings[:object]

        if user.persisted?
          view.link_to(user.id, value, target: '_blank')
        end
      end
    end

    edit do
      field :role
      field :user_next_services_path

      field :addresses

      field :zone do
        formatted_value do
          value.name if value
        end
        read_only true
      end

      field :first_name
      field :last_name
      field :email
      field :phone
      field :password do
        required false
      end
      field :password_confirmation

      field :banned_aliadas

      field :services

      group :informacion_de_pago do

        field :balance do
          virtual? 
          read_only true
          help 'Creditos menos deuda'
        end

        field :points do
          label 'Creditos'
        end

        field :default_payment_provider do
          visible do
            value.present?
          end

          formatted_value do
            if value.present?
              Mixins::RailsAdminModelsHelpers.rails_admin_edit_link(value)
            end
          end

          read_only true
        end

        field :conekta_customer_id do
          read_only true
        end

      end


      group :login_info do
        active false
        field :current_sign_in_at
        field :sign_in_count
        field :last_sign_in_at
        field :last_sign_in_ip
        field :current_sign_in_ip
        field :remember_created_at
        field :reset_password_sent_at
      end
    end

    list do
      search_scope do
        Proc.new do |scope, query|
          query_without_accents = I18n.transliterate(query)

          scope.merge(UnscopedUser.with_name_phone_email(query_without_accents))
        end
      end

      field :user_next_services_path do
        read_only true

        formatted_value do
          view = bindings[:view]
          user = bindings[:object]

          if user.persisted?
            view.link_to(user.id, value, target: '_blank')
          end
        end
      end

      field :role do
        queryable false
        filterable false
        visible false
      end
      field :full_name do
        queryable false
        filterable false
      end
      field :email do
        queryable false
        filterable false
      end
      field :phone do
        queryable false
        filterable false
      end

      field :default_address_link do
        virtual?
      end

      field :created_at
    end

    show do
      exclude_fields :payment_provider_choices, :versions, :code, :sign_in_count
      include_fields :user_next_services_path
    end
  end
end

class User < ActiveRecord::Base

  #Required to enable token authentication
  acts_as_token_authenticatable

  include Presenters::UserPresenter
  include UsersHelper


  ROLES = [
    ['client', 'Cliente'],
    ['aliada', 'Aliada'],
    ['admin', 'Admin'],
  ]

  has_many :services, inverse_of: :user, foreign_key: :user_id
  has_many :addresses
  has_and_belongs_to_many :banned_aliadas,
                          class_name: 'Aliada',
                          join_table: :banned_aliada_users,
                          foreing_key: :user_id,
                          association_foreign_key: :aliada_id

  has_many :payment_provider_choices, -> { order('payment_provider_id DESC') }, inverse_of: :user

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  before_validation :ensure_password
  before_validation :set_default_role

  default_scope { where('users.role in (?)', ['client', 'admin']) }

  validates :role, inclusion: {in: ROLES.map{ |pairs| pairs[0] } }
  



  def self.email_exists?(email)
    ## Devise is configured to save emails in lower case
    User.find_by_email(email.strip.downcase).present?
  end

  def create_first_payment_provider!(payment_method_id)
    payment_method = PaymentMethod.find(payment_method_id)
    payment_provider = payment_method.provider_class.create!

    create_payment_provider_choice(payment_provider)
  end
  
  # Given a service id, check whether status is finished,
  # charge the default service provider and change status to finished
  # 
  def charge_service!(id_s)
    service_to_charge = Service.find_by(id: id_s, user_id: self.id, status: 'finished')
    
    
   # binding.pry
    if service_to_charge
      begin
        amount = service_to_charge.amount_to_bill
        product = OpenStruct.new({price: amount,
                                   description: 'Servicio aliada',
                                   id: id_s})
    #    binding.pry
        default_payment_provider.charge!(product, self)
        
        
        ### Exception handler for when a users payment method does not riff  
      rescue Conekta::Error => err
        Ticket.create_error(relevant_object_id: id_s,
                            relevant_object_type: 'Service',
                            message: "No se pudo realizar cargo de #{amount} a la tarjeta de #{self.first_name} #{self.last_name}. #{err.message_to_purchaser}")
      end
    else
      Ticket.create_warning(relevant_object_id: id_s,
                            relevant_object_type: 'Service',
                            message: "Se intento cobrar servicio #{id_s} pero no ha concluido o no existe")
    end  
  end
  
  def create_payment_provider_choice(payment_provider)
    # Switch the default
    PaymentProviderChoice.where(user: self).update_all default: false

    # The newest is the default
    PaymentProviderChoice.create!(payment_provider: payment_provider, default: true, user: self)
  end

  def default_payment_provider
    payment_provider_choices.default.provider
  end

  def past_aliadas
    services.in_the_past.joins(:aliada).order('aliada_id').map(&:aliada)
  end

  def set_default_role
    self.role ||= 'client' if self.respond_to? :role
  end

  def ensure_password
    self.password ||= generate_random_pronouncable_password if self.respond_to? :password
  end

  def ensure_first_payment!(payment_method_options)
    default_payment_provider.ensure_first_payment!(self, payment_method_options)
  end

  def admin?
    role == 'admin'
  end

  def timezone
    'Mexico City'
  end

  rails_admin do
    navigation_label 'Personas'
    navigation_icon 'icon-user'
    exclude_fields :payment_provider_choices
    label_plural 'usuarios'

    list do
      configure :name do
        virtual?
      end

      configure :default_address do
        virtual?
      end

      configure :next_service do
        virtual?
      end

      include_fields :name, :email, :default_address, :next_service
    end

    edit do
      field :role
      field :first_name
      field :last_name
      field :phone
      group :login_info do
        active false
        field :password
        field :password_confirmation
        field :current_sign_in_at
        field :sign_in_count
        field :last_sign_in_at
        field :last_sign_in_ip
        field :current_sign_in_ip
        field :remember_created_at
        field :reset_password_sent_at
      end
    end
  end
end

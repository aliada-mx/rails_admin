class User < ActiveRecord::Base
  ROLES = [
    ['client', 'Cliente'],
    ['aliada', 'Aliada'],
    ['admin', 'Admin'],
  ]
  validates :role, inclusion: {in: ROLES.map{ |pairs| pairs[0] } }

  include UsersHelper
  has_many :services
  has_many :addresses
  has_and_belongs_to_many :banned_aliadas,
                          class_name: 'User',
                          join_table: :banned_aliada_users,
                          foreing_key: :user_id,
                          association_foreign_key: :aliada_id

  has_many :payment_provider_choices

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  before_validation :ensure_password
  before_validation :set_default_role

  default_scope { where('users.role != ?', 'aliada')}

  def create_first_payment_provider!(payment_method_id)
    payment_method = PaymentMethod.find(payment_method_id)
    payment_provider = payment_method.provider_class.create!
    PaymentProviderChoice.find_or_create_by!(payment_provider: payment_provider, default: true, user: self)
  end

  def default_payment_provider
    payment_provider_choices.default
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

  def name
    "#{first_name} #{last_name}"
  end
end

class User < ActiveRecord::Base
  ROLES = [
    ['client', 'Cliente'],
    ['aliada', 'Aliada'],
    ['admin', 'Admin'],
  ]
  validates :role, inclusion: {in: ROLES.map{ |pairs| pairs[0] } }

  include UsersHelper
  has_many :services, inverse_of: :user
  has_many :addresses, inverse_of: :user

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  before_validation :ensure_password
  default_scope { where("role != ?", 'aliada') }
  before_validation :set_default_role

  def set_default_role
    self.role ||= 'client' if self.respond_to? :role
  end

  def ensure_password
    self.password ||= generate_random_pronouncable_password if self.respond_to? :password
  end
end

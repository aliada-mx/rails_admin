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

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  before_validation :ensure_password
  before_validation :set_default_role

  def past_aliadas
    services.in_the_past.joins(:aliada).order('aliada_id').map(&:aliada)
  end

  def set_default_role
    self.role ||= 'client' if self.respond_to? :role
  end

  def ensure_password
    self.password ||= generate_random_pronouncable_password if self.respond_to? :password
  end
end

class Zone < ActiveRecord::Base
  has_many :postal_code_zones
  has_many :postal_codes, through: :postal_code_zones

  def self.find_by_postal_code(postal_code)
    Zone.joins(:postal_codes).where('postal_codes.id = ?', postal_code.id).try(:first)
  end

  def self.find_by_code(code)
    Zone.joins(:postal_codes).where('postal_codes.code = ?', code).try(:first)
  end
end

# -*- encoding : utf-8 -*-
class Code < ActiveRecord::Base
  belongs_to :user
  belongs_to :code_type

  rails_admin do
    visible false
  end

  def self.generate_unique_code user, code_type
    c = Code.new
    c.user = user
    c.code_type = code_type
    c.amount =  code_type.value 
    name = self.generate_unique_name user.first_name
    while self.find_by(name: name)
      name = self.generate_unique_name user.first_name
    end
    c.name = name 
    c.save!
  end

  def self.generate_unique_name first_name
    numbers = %w{1 2 3 4 5 6 7 8 9}
    words = %w{lavado higiene aseo cepillado barrido cuidado limpieza sanidad escoba trapeador jabon detergente aroma servicio cocina ropa camisa reluciente especial relajante}
    return "#{first_name}#{words[rand*words.size]}#{numbers[rand*numbers.size]}#{numbers[rand*numbers.size]}".downcase
  end
end

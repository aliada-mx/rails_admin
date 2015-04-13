# -*- encoding : utf-8 -*-
class UnscopedUser < User
  scope :with_name_phone_email, -> (query) do
    unaccented = I18n.transliterate(query)
    query = "%#{unaccented .downcase}%"
    
    where('lower( unaccent(users.full_name) ) ILIKE ? OR 
           lower( unaccent(users.first_name) ) ILIKE ? OR 
           lower( unaccent(users.last_name) ) ILIKE ? OR 
           users.email ILIKE ? OR 
           users.phone ILIKE ?', *[ query ]*5)
  end

  def self.default_scope
  end
end

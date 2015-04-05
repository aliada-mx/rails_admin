class UnscopedUser < User
  scope :with_name_phone_email, -> (query) do
    query = "%#{query}%"
    where('users.first_name ILIKE ? OR users.last_name ILIKE ? OR users.email ILIKE ? OR users.phone ILIKE ?', *[ query ]*4)
  end

  def self.default_scope
  end
end

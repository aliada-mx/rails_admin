class Aliada < User
  # We uses this instead of default_scope to be able to override it from the
  # parent class
  def self.default_scope 
    where(role: 'aliada')
  end
end

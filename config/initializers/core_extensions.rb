# config/initializers/core_extensions.rb
class ActiveRecord::Base

  def in_rails_admin
    @in_rails_admin ||= false
  end

  def in_rails_admin=(value)
    @in_rails_admin = value
  end
end

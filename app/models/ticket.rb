class Ticket < ActiveRecord::Base
  belongs_to :relevant_object, polymorphic: true

  def self.create_warning(options)
    options.merge!({classification: 'warning'})
    Ticket.create(options)
  end
end

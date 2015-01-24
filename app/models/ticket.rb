class Ticket < ActiveRecord::Base
  belongs_to :relevant_object, polymorphic: true

  def self.create_warning(options)
    Ticket.create(type: 'warning', options)
  end
end

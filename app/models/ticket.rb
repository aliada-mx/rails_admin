class Ticket < ActiveRecord::Base
  belongs_to :relevant_object, polymorphic: true

  def self.create_warning(options)
    options.merge!({classification: 'warning'})
    Ticket.create(options)
  end

  rails_admin do
    label_plural 'tickets'
    weight -1
    navigation_label 'Operación'
    navigation_icon 'icon-warning-sign'

  end
end

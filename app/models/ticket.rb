class Ticket < ActiveRecord::Base
  CLASSIFICATIONS = {
    'alert-info' => 'Atención',
    'alert-success' => 'Resuelto',
    'alert-warning' => 'Advertencia',
    'alert-danger' => 'Problema',
  }
  # Only classifications with bootstrap classes allowed
  validates :classification, inclusion: {in: CLASSIFICATIONS.keys  }

  belongs_to :relevant_object, polymorphic: true

  def classification_name
    CLASSIFICATIONS[self.classification]
  end

  # def classification_enum
  #   CLASSIFICATIONS.invert
  # end

  def classification_partial

  end

  def self.create_warning(options)
    options.merge!({classification: 'alert-warning'})
    Ticket.create(options)
  end

  rails_admin do
    label_plural 'tickets'
    weight -9
    navigation_label 'Operación'
    navigation_icon 'icon-warning-sign'

    configure :classification do
      label 'clasificación'
      read_only true
      formatted_value do
        view = bindings[:view]
        ticket = bindings[:object]

        view.content_tag(:div, ticket.classification_name, {class: "alert #{value} ticket-alert"})
      end
      help ''
    end

    edit do 
      configure :classification, :enum do
        read_only false
        enum do
          CLASSIFICATIONS.invert
        end
      end
    end
  end
end

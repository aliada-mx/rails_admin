# -*- coding: utf-8 -*-
class Ticket < ActiveRecord::Base
  CLASSIFICATIONS = {
    'alert-info' => 'Atención',
    'alert-success' => 'Resuelto',
    'alert-warning' => 'Advertencia',
    'alert-danger' => 'Problema',
  }

  CATEGORIES = {
    'conekta_charge_failure' => 'Error al cobrar conekta',
    'schedule_filler_error' => 'Error en el creador de disponibilidad',
    'availability_missing' => 'Falta de disponbilidad',
  }

  # Only classifications with bootstrap classes allowed
  validates :classification, inclusion: {in: CLASSIFICATIONS.keys  }
  validates :category, inclusion: {in: CATEGORIES.keys  }

  belongs_to :relevant_object, polymorphic: true

  def classification_name
    CLASSIFICATIONS[self.classification]
  end

  def category_name
    CATEGORIES[self.category]
  end

  def self.create_error(options)
    options.merge!({classification: 'alert-danger'})
    Ticket.create(options)
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

        if view
          view.content_tag(:div, ticket.classification_name, {class: "alert #{value} ticket-alert"})
        else
          ''
        end
      end
      help ''
    end

    configure :message do
      css_class "ticket-message"

      pretty_value do
        value.html_safe
      end
    end

    configure :relevant_object do
      css_class "ticket-relevant_object"
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

class IncompleteService < ActiveRecord::Base
  belongs_to :service
  belongs_to :service_type

  def self.mark_as_complete(params, service)
    incomplete_service = IncompleteService.find(params[:id])
    incomplete_service.service = service
    incomplete_service.postal_code_not_found = false
    incomplete_service.save!
  end

  def is_complete?
    self.service.present?
  end

  rails_admin do
    label_plural 'Registros inconclusos'
    parent Service
    navigation_icon 'icon-eye-close'

    configure :service do
      help 'Si hay servicio, el registro se completo'
    end

    configure :is_complete?, :boolean do
      virtual?
      label '¿Completado?'
    end


    list do
      sort_by :created_at
      include_fields :email, :postal_code_number, :postal_code_not_found, :is_complete?, :created_at

      field :created_at do
        sort_reverse true
        pretty_value do
          value.in_time_zone('Mexico City')
        end
      end
    end
  end
end

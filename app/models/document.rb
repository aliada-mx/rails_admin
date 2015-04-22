# -*- encoding : utf-8 -*-
class Document < ActiveRecord::Base
  belongs_to :aliada, inverse_of: :documents, foreign_key: :user_id

  has_attached_file :file

  rails_admin do
    label_plural 'archivos'
    parent Aliada
    navigation_icon 'icon-briefcase'
  end
end

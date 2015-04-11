# -*- encoding : utf-8 -*-
class Document < ActiveRecord::Base
  belongs_to :aliada, inverse_of: :documents, foreign_key: :user_id

  has_attached_file :file
  validates_attachment_content_type :file, content_type: ['image/jpg',
                                                          'image/jpeg',
                                                          'image/png',
                                                          'image/gif',
                                                          'image/svg+xml']

  rails_admin do
    label_plural 'archivos'
    parent Aliada
    navigation_icon 'icon-briefcase'
  end
end

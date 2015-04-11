# -*- encoding : utf-8 -*-
class RemoveAttachmentFromExtras < ActiveRecord::Migration
  def change
    remove_column :extras, "attachment_file_name"
    remove_column :extras, "attachment_content_type"
    remove_column :extras, "attachment_file_size"
    remove_column :extras, "attachment_updated_at"
  end
end

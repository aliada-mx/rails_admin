# -*- encoding : utf-8 -*-
class Setting < Settingslogic
source "#{Rails.root}/config/application.yml"
namespace Rails.env
end

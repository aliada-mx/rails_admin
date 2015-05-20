# -*- encoding : utf-8 -*-
module Presenters
  module AliadaPresenter
    def average_score
      scores.average(:value)
    end

    def services_worked
      services.not_canceled.finished.count
    end

    def services_unassigned_this_month
      service_unassignments.where(created_at: this_month_range).count
    end

    def show_unassignment_warning
      services_unassigned_this_month <= Setting.aliada_unassignments_per_month - 1
    end
  end
end

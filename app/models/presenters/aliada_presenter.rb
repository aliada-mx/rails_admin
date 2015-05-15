# -*- encoding : utf-8 -*-
module Presenters
  module AliadaPresenter
    def average_score
      scores.average(:value)
    end

    def services_worked
      services.not_canceled.finished.count
    end

    def unassignments_left
      service_unassignments
    end

    def services_unassigned_this_month
      services.unassigned.count
    end
  end
end

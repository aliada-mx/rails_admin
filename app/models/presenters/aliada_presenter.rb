# -*- encoding : utf-8 -*-
module Presenters
  module AliadaPresenter
    def average_score
      scores.average(:value)
    end

    def services_worked
      services.not_canceled.finished.count
    end
  end
end

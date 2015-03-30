module AliadaExceptions
  class AvailabilityNotFound < StandardError
  end

  class ServiceDowgradeImpossible < StandardError
  end

  class PaymentGatewayError < StandardError
  end
end

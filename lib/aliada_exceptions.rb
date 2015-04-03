module AliadaExceptions

  class AvailabilityNotFound < StandardError
    attr_accessor :object

    def initialize(message: nil, object: {})
      super(message)
      self.object = object
    end
  end

  class ServiceDowgradeImpossible < StandardError
  end

  class PaymentGatewayError < StandardError
  end
end

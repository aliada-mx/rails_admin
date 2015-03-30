class CreditsCharger
  attr_reader :payment
  attr_reader :amount
  attr_reader :left_to_charge

  def initialize(amount, user)
    @user = user
    @amount = amount
    @left_to_charge = amount

    @should_create_payment = true

    calculate_amount_to_charge
  end


  def charge!
    @user.balance -= @amount_to_charge
    @user.save!

    if @should_create_payment
      @payment = Payment.create_from_credit_payment(@amount, @user)
    end

    self
  end

  private
    def calculate_amount_to_charge
      if @user.balance <= 0
        @should_create_payment = false
        @left_to_charge = @amount
        @amount_to_charge = 0

      elsif @user.balance >= @amount
        @left_to_charge = 0
        @amount_to_charge = @amount

      elsif @user.balance < @amount 
        @left_to_charge = @amount - @user.balance
        @amount_to_charge = @user.balance

      end
    end
end

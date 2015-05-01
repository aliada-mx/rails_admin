# -*- encoding : utf-8 -*-
class PointsCharger
  attr_reader :payment
  attr_reader :amount
  attr_reader :left_to_charge

  def initialize(amount, user, service)
    @user = user
    @amount = amount
    @service = service
    @left_to_charge = amount

    @should_create_payment = true

    calculate_amount_to_charge
  end


  def charge!
    @user.points -= @amount_to_charge
    @user.save!

    if @should_create_payment
      @payment = Payment.create_from_credit_payment(@amount, @user, @service)
    end

    self
  end

  private
    def calculate_amount_to_charge
      if @user.points <= 0
        @should_create_payment = false
        @left_to_charge = @amount
        @amount_to_charge = 0

      elsif @user.points >= @amount
        @left_to_charge = 0
        @amount_to_charge = @amount

      elsif @user.points < @amount 
        @left_to_charge = @amount - @user.points
        @amount_to_charge = @user.points

      end
    end
end

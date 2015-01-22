module ServiceHelper
  # Tries to find one of the user addreses
  # matching the postal code or new address
  def suggest_address(user, postal_code)
    addresses = user.addresses.where(postal_code_id: postal_code.id)

    if addresses.exists?
      addresses.first
    else
      Address.new(postal_code_id: @postal_code.id)
    end
  end
end

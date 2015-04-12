# -*- encoding : utf-8 -*-
class TwoLevelHash < Hash
  def initialize
    super { |hash, key| hash[key] = Hash.new{ |h,k| h[k] = {} } }
  end
end

module SubArrayPatch
  def is_subarray?(other_array)
    !self.any? {|e| !other_array.include?(e)}
  end
end

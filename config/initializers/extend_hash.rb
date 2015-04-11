# -*- encoding : utf-8 -*-
#  Netsted Hash:
# 
#  str_hash = {
#                "a"  => "a val", 
#                "b"  => "b val",
#                "c" => {
#                          "c1" => "c1 val",
#                          "c2" => "c2 val"
#                        }, 
#                "d"  => "d val",
#           }
#           
# mappings = {
#              "a" => "apple",
#              "b" => "boss",
#              "c" => "cat",
#              "c1" => "cat 1"
#           }
# => {"apple"=>"a val", "boss"=>"b val", "cat"=>{"cat 1"=>"c1 val", "c2"=>"c2 val"}, "d"=>"d val"}
#
class Hash
  def rename_keys(mapping)
    result = {}
    self.map do |k,v|
      mapped_key = mapping[k] ? mapping[k] : k
      result[mapped_key] = v.kind_of?(Hash) ? v.rename_keys(mapping) : v
      result[mapped_key] = v.collect{ |obj| obj.rename_keys(mapping) if obj.kind_of?(Hash)} if v.kind_of?(Array)
    end
    result
  end
end

module TestingSupport
  module CapybaraHelpers
    def fill_hidden_input(element_id, with: '') 
      find(:xpath, "//input[@id='#{element_id}']").set with
    end
  end
end

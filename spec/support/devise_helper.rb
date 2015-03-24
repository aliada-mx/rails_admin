module TestingSupport
  module DeviseHelpers
    def login_as(user)
      visit(new_user_session_path)
      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: user.password
      click_button 'Entrar'
    end

    def logout
      visit(destroy_user_session_path)
    end
  end
end

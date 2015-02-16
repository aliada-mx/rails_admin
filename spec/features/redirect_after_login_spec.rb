feature 'Redirect after login' do
  let!(:user) { create(:user) }

  context 'a logged out user that tries to visit logged in exclusive pages' do
    it 'gets redirected to the next services path after login' do
      login_as(user)

      expect(current_path).to eq next_services_users_path(user)
    end

    it 'gets redirected to the login path' do
      visit next_services_users_path(user)

      expect(current_path).to eq new_user_session_path
    end

    it 'gets redirected to the page it was trying to access after login' do
      visit previous_services_users_path(user)

      expect(current_path).to eq new_user_session_path
      login_as(user)

      expect(current_path).to eq previous_services_users_path(user)
    end
  end
end

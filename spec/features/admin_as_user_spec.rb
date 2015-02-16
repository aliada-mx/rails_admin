feature 'Admin ability to browse as a user' do
  let!(:user){ create(:user) }
  let!(:admin){ create(:admin) }

  context 'a logged in admin' do
    it 'can visit another user profile' do
      login_as(admin)

      visit(next_services_users_path(user))

      expect(current_path).to eql next_services_users_path(user)
    end

    it 'cannot be visited by a regular user' do
      login_as(user)

      visit(next_services_users_path(admin))

      expect(current_path).not_to eql next_services_users_path(user)
      expect(current_path).to eql main_app.root_path
    end
  end
end

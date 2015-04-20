feature 'Create users in admin' do
  let!(:admin) { create(:admin) }

  it 'should let an admin create a new user' do
    login_as(admin)

    new_user_url = RailsAdmin::Engine.routes.url_helpers.new_path('User')

    visit(new_user_url)
    expect(page).to have_content('Nuevo usuario')
  end
end

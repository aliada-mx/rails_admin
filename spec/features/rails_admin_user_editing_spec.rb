# -*- encoding : utf-8 -*-
feature 'Edit a user in admin' do
  let!(:admin) { create(:admin) }
  let!(:user) { create(:user) }

  it 'lets an admin add points to a user' do
    login_as(admin)

    edit_user_url = RailsAdmin::Engine.routes.url_helpers.edit_path('User', user)

    visit(edit_user_url)

    fill_in 'Creditos', with: 133

    click_button 'Guardar'

    user.reload
    expect(user.points).to eql 133
  end
end

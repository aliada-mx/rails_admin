# -*- encoding : utf-8 -*-
feature 'Create aliadas in admin' do
  let!(:admin) { create(:admin) }

  it 'should let an admin create a new aliada' do
    login_as(admin)

    new_user_url = RailsAdmin::Engine.routes.url_helpers.new_path('Aliada')

    visit(new_user_url)
    expect(page).to have_content('Nuevo aliada')
  end
end

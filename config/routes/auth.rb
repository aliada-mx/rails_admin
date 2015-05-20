# Authentication and authorization
devise_for :users, path: '', path_names: {
  sign_in: :login,
  sign_out: :logout
}

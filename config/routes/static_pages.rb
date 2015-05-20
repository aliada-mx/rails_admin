# Static pages
root to: 'static_pages#home'
get 'como-funciona', to: 'static_pages#how_it_works', as: :how_it_works
get 'precios', to: 'static_pages#prices', as: :prices
get 'faq', to: 'static_pages#faq', as: :faq
get 'terminos', to: 'static_pages#terms', as: :terms
get 'privacidad', to: 'static_pages#privacy', as: :privacy
get 'patrones', to: 'static_pages#pattern_dictionary'
get 'jobs', to: 'static_pages#jobs', as: :jobs
get 'reclutamiento', to: 'static_pages#recruitment', as: :recruitment
get 'reclutamiento/registro', to: 'static_pages#recruitment_signup', as: :recruitment_signup

Aliada web app
======

# Dev env

The recommended way to run the app is in a contained gemset using rvm.

1. Install rvm
    https://rvm.io/rvm/install
1. Install ruby 2.1.1
    rvm install 2.1.1
1. Create a gemset
    rvm gemset create aliada
1. Clone the repo
    git clone https://github.com/grillermo/aliada.git
1. Bundle the requirements
    bundle install
1. Install Postgresql
    https://wiki.postgresql.org/wiki/Detailed_installation_guides
1. Create a new database called 
    aliada_development
1. Run migrations
    bundle exec rake db:migrate
    
To run the app

1. Activate the gemset
    rvm gemset use aliada
1. Run the development server
    rails server

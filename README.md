Aliada web app
======

### Setting up the development environment

The recommended way to run the app is in a contained gemset using rvm.

1. Install rvm
    ```
    https://rvm.io/rvm/install
    ```
2. Install ruby 2.1.5
    ```
    rvm install 2.1.5
    ```
3. Create a gemset
    ```
    rvm gemset create aliada
    ```
4. Clone the repo
    ```
    git clone https://github.com/grillermo/aliada.git
    ```
5. Bundle the requirements
    ```
    bundle install
    ```
6. Install Postgresql
    ```
    https://wiki.postgresql.org/wiki/Detailed_installation_guides
    ```
7. Create a new database called 
    ```
    aliada_development
    ```
8. Run migrations
    ```
    bundle exec rake db:migrate
    ``` 

### To run the app

1. Activate the gemset
    ```
    rvm gemset use aliada
    ```
2. Run the development server
    ```
    rails server
    ```

### Developing with workers

1. Run redis
  ```
  redis-server /usr/local/etc/redis.conf
  ```

2. Run the resque worker
  ```
  bundle exec rake resque:work QUEUE=*
  ```

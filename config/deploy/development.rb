set :default_env, { 'ROBOT_ENVIRONMENT' => 'development' }
server 'hostname.edu', user: 'userid', roles: %w{app}
Capistrano::OneTimeKey.generate_one_time_key!


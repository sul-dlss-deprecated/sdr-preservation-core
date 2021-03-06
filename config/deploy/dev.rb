# Note: capistrano reads this file AFTER config/deploy.rb

set :default_env, {
  # ROBOT_ENVIRONMENT implies remote :deploy_to contains
  # config/environments/#{ROBOT_ENVIRONMENT}.rb
  # config/environments/robots_#{ROBOT_ENVIRONMENT}.rb
  'ROBOT_ENVIRONMENT' => 'integration'
}

server 'sul-sdr-services-dev.stanford.edu', user: 'sdr2service', roles: %w{app}

Capistrano::OneTimeKey.generate_one_time_key!

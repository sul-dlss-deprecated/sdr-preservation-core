# Note: capistrano reads this file AFTER config/deploy.rb

# User for deployment
if ENV['SDR_USER'].nil?
  ask :user, 'for deployment to user@hostname'
  ENV['SDR_USER'] = fetch(:user)
end

# Server deployed to
if ENV['SDR_HOST'].nil?
  ask :hostname, 'for deployment to user@hostname'
  ENV['SDR_HOST'] = fetch(:hostname)
end

ENV['SDR_APP']  ||= fetch(:application)
ENV['SDR_HOST'] ||= 'localhost'
ENV['SDR_USER'] ||= `echo $USER`.chomp
puts 'deploy/development.rb ENV:'
puts "ENV['SDR_APP']  = #{ENV['SDR_APP']}"
puts "ENV['SDR_HOST'] = #{ENV['SDR_HOST']}"
puts "ENV['SDR_USER'] = #{ENV['SDR_USER']}"
puts

# Set the ENV on the remote system given by ENV['SDR_HOST']
set :default_env, {
    # ROBOT_ENVIRONMENT implies remote :deploy_to path contains:
    # config/environments/#{ROBOT_ENVIRONMENT}.rb
    # config/environments/robots_#{ROBOT_ENVIRONMENT}.rb
    'ROBOT_ENVIRONMENT' => 'development',
    'SDR_APP'  => ENV['SDR_APP'],
    'SDR_USER' => ENV['SDR_USER'],
    'SDR_HOST' => ENV['SDR_HOST'],
}

require_relative 'server_settings'



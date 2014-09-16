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

server ENV['SDR_HOST'], user: ENV['SDR_USER'], roles: %w{app}
Capistrano::OneTimeKey.generate_one_time_key!

# Target path
USER_HOME = `ssh #{ENV['SDR_USER']}@#{ENV['SDR_HOST']} 'echo $HOME'`.chomp
set :deploy_to, "#{USER_HOME}/#{ENV['SDR_APP']}"

set :repo_url, "https://github.com/sul-dlss/#{ENV['SDR_APP']}.git"


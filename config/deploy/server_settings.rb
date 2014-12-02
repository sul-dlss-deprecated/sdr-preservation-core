# Note: this file is required from config/deploy/<environment>.rb

puts "ENV['SDR_APP']  = #{ENV['SDR_APP']}"
puts "ENV['SDR_HOST'] = #{ENV['SDR_HOST']}"
puts "ENV['SDR_USER'] = #{ENV['SDR_USER']}"
puts "ENV['ROBOT_ENVIRONMENT'] = #{ENV['ROBOT_ENVIRONMENT']}"
puts

set :default_env, {
  # ROBOT_ENVIRONMENT implies remote :deploy_to contains
  # config/environments/#{ROBOT_ENVIRONMENT}.rb
  # config/environments/robots_#{ROBOT_ENVIRONMENT}.rb
  'ROBOT_ENVIRONMENT' => ENV['ROBOT_ENVIRONMENT'],
  'SDR_APP'  => ENV['SDR_APP'],
  'SDR_USER' => ENV['SDR_USER'],
  'SDR_HOST' => ENV['SDR_HOST'],
}

server ENV['SDR_HOST'], user: ENV['SDR_USER'], roles: %w{app}
Capistrano::OneTimeKey.generate_one_time_key!
ssh_opts = fetch(:ssh_options)
ssh_opts[:forward_agent] = true
ssh_opts[:verbose] = false
# The :ssh_options are set by
# capistrano-one_time_key/blob/master/lib/capistrano/tasks/one_time_key.rake

# Target path
USER_HOME = `ssh #{ENV['SDR_USER']}@#{ENV['SDR_HOST']} 'echo $HOME'`.chomp
APP_HOME = "#{USER_HOME}/#{ENV['SDR_APP']}"
set :deploy_to, APP_HOME

namespace :deploy do
  desc 'Upload environment configuration files to the remote server'
  task :upload_configs do
    on release_roles :all do
      within shared_path do
        #SERVER_CONFIG_ENV_PATH = "#{ENV['SDR_USER']}@#{ENV['SDR_HOST']}:#{APP_HOME}/shared/config/environments/"
        # Upload the required environment config files
        CONFIG_DEPLOY_PATH = File.absolute_path(File.dirname(__FILE__))
        CONFIG_ENV_PATH = CONFIG_DEPLOY_PATH.sub('config/deploy', 'config/environments')
        CONFIG_ENV_FILE = "#{CONFIG_ENV_PATH}/#{ENV['ROBOT_ENVIRONMENT']}.rb"
        CONFIG_ROBOT_FILE = "#{CONFIG_ENV_PATH}/robots_#{ENV['ROBOT_ENVIRONMENT']}.yml"
        [ CONFIG_ENV_FILE, CONFIG_ROBOT_FILE ].each do |local_path|
          if File.exist? local_path
            #`scp #{local_path} #{SERVER_CONFIG_ENV_PATH}`
            config_file = File.join(shared_path, "config","environments", File.basename(local_path))
            info "Uploading local config file: #{local_path}"
            upload! StringIO.new(IO.read(local_path)), config_file
          else
            fail "Missing config file: #{local_path}"
          end
        end
      end
    end
  end
end
after "deploy:check:linked_dirs", "deploy:upload_configs"


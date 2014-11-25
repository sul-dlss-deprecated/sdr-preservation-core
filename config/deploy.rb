# config valid only for Capistrano 3.x
lock '3.2.1'

set :application, 'sdr-preservation-core'

# Default value for :scm is :git
# set :scm, :git
set :repo_url, 'https://github.com/sul-dlss/sdr-preservation-core.git'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, %w(log run config/environments config/certs)

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do
  # the sshkit's test method will return to this script even if the call to stop or quit fails
  # http://vladigleba.com/blog/2014/04/10/deploying-rails-apps-part-6-writing-capistrano-tasks/
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 10 do
      within release_path do
        test :bundle, :exec, :controller, :stop
        test :bundle, :exec, :controller, :quit
        execute :bundle, :exec, :controller, :boot
      end
    end
  end
  # Capistrano 3 no longer runs deploy:restart by default.
  after :publishing, :restart
end

# capistrano next reads config/deploy/#{target}.rb, e.g.:
# config/deploy/development.rb


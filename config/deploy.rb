# config valid only for Capistrano 3.x
#lock '3.2.1'

set :application, 'sdr-preservation-core'

# Default value for :scm is :git
# set :scm, :git

# ssh access to github is restricted, using https instead (see config/deploy/github_repo.rb)
#set :repo_url, 'git@github.com:sul-dlss/sdr-preservation-core.git'

# Ensure config/deploy/github_repo.rb contains the following content, where
# AuthUser:AuthToken is replaced with credentials for authorized access to the repository.
# The personal access token should have at least the 'repo' scope.
# https://help.github.com/articles/creating-an-access-token-for-command-line-use/
# https://github.com/blog/1509-personal-api-tokens
#set :repo_url, 'https://AuthUser:AuthToken@github.com/sul-dlss/sdr-preservation-core.git'
require_relative 'deploy/github_repo'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
#set :log_level, :info

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

# capistrano next reads config/deploy/#{server}.rb, where #{server} is the first argument to cap; e.g.:
# cap localhost deploy:check # invokes config/deploy/localhost.rb
# cap test1 deploy:check # invokes config/deploy/test1.rb
# cap test2 deploy:check # invokes config/deploy/test2.rb


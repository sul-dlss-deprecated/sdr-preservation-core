source 'https://rubygems.org'

gem 'confstruct'
gem 'dotenv'
gem 'json_pure'
gem 'nokogiri'
gem 'rake'
gem 'rest-client'
gem 'sys-filesystem'
gem 'pry'

# DLSS gems
gem 'dor-workflow-service', '~> 1.8'
gem 'druid-tools'
gem 'lyber-core', '~> 3.3'
gem 'moab-versioning', '~> 2.0'
gem 'robot-controller', '~> 2.0'
gem 'sdr-replication', '~> 1.0'

group :development do
  gem 'awesome_print'
  gem 'equivalent-xml'
  gem 'fakeweb'
  gem 'pry-doc'
  gem 'rspec',  '~> 3.0'
  gem 'simplecov'
  gem 'coveralls'
  gem 'yard'
end

# Do not place the capistrano-related gems in the default or development bundle group
# Otherwise a Bundle.require command might try to load them
# leading to failure because these gem's rake task files use capistrano DSL.
group :deployment do
  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.1'
  gem 'capistrano-bundler', '~> 1.1'
  gem 'capistrano-rvm', '~> 0.1'
  gem 'dlss-capistrano', '~> 3.0'
end


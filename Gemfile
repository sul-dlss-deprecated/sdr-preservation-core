source 'https://rubygems.org'

gem 'confstruct'
gem 'json_pure'
gem 'nokogiri'
gem 'rake'
gem 'rest-client'
gem 'sys-filesystem'
gem 'pry'

# DLSS gems
gem 'dor-workflow-service', '~> 1.7'
gem 'druid-tools'
gem 'lyber-core',  '~> 3.2', '>= 3.2.2'
gem 'moab-versioning', '~> 1.3' #, :path => '/Users/rnanders/Code/Github/moab-versioning' #
gem 'robot-controller', '~> 2.0'
gem 'sdr-replication', '~> 0.5' #,:path => '/Users/rnanders/Code/Github/sdr-replication' #

group :development do
	gem 'awesome_print'
	gem 'equivalent-xml'
	gem 'fakeweb'
	gem 'rspec', '~> 2.14'
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
  gem 'lyberteam-capistrano-devel', '~> 3.0'
end

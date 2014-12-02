# Note: capistrano reads this file AFTER config/deploy.rb

ENV['SDR_APP']  ||= fetch(:application)
ENV['SDR_HOST'] ||= 'localhost'
ENV['SDR_USER'] ||= ENV['USER']

ENV['ROBOT_ENVIRONMENT'] = 'development'

puts File.expand_path(__FILE__)
require_relative 'server_settings'


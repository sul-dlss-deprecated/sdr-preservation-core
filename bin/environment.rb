#!/usr/bin/env ruby

# environment.rb

require 'rubygems'
require 'bundler/setup'
require 'pathname'

BinHome = Pathname(__FILE__).expand_path.parent
AppHome = BinHome.parent
LibHome = AppHome.join('lib')

$LOAD_PATH.unshift(BinHome.to_s) unless $LOAD_PATH.include?(BinHome.to_s)
$LOAD_PATH.unshift(LibHome.to_s) unless $LOAD_PATH.include?(LibHome.to_s)

require 'status'

# The name of the current computer without the domain

# Make sure a value is set for ROBOT_ENVIRONMENT
ENV['ROBOT_ENVIRONMENT'] = (
  case `hostname -s`.chomp
    when "sdr-services"
      'production'
    when "sdr-services-test"
      'staging'
    when "sul-sdr-services-dev"
      'integration'
    else
      'development'
  end
)

WorkflowNames = AppHome.join('config','workflows').children.map{|child| child.basename.to_s}.sort

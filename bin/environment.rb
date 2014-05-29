#!/usr/bin/env ruby

# environment.rb

require 'rubygems'
require 'bundler/setup'
require 'pathname'
require_relative '../lib/libdir'
require_relative 'status'

BinHome = Pathname(__dir__)
AppHome = BinHome.parent

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

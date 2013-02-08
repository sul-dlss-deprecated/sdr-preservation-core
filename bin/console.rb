#!/usr/bin/env ruby

bindir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(bindir) unless $LOAD_PATH.include?(bindir)


libdir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'irb'
IRB.start

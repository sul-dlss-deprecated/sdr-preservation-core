$: << File.join(File.dirname(__FILE__), "./fixtures")

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "robots")
require 'spec'
 
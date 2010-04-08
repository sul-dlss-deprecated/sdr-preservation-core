$: << File.join(File.dirname(__FILE__), "/../lib")
$: << File.join(File.dirname(__FILE__), "/../robots")
$: << File.join(File.dirname(__FILE__), "./fixtures")

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "robots")
$:.unshift File.join(File.dirname(__FILE__), "..", "models")
require 'spec'
 
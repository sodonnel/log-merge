# hack to get the CLI working witout being properly installed as a gem
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib"))

require 'log-merge'

LogMerge::MergeCLI.run(ARGV)

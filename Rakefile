require 'rubygems'
require 'rake'
require 'yaml'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/lib')

require 'boot'

desc "Start the server"
task :start do
  Kernel.exec "bundle exec foreman start"
end

desc "Start the directory watch process"
task :watch do
  watch = Transcode::Watch.new
  watch.start
end

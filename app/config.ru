require 'rubygems'
require 'sinatra.rb'

root_dir = Pathname(__FILE__).dirname

set :root, root_dir
set :views, File.join(File.dirname(__FILE__), 'app','views')
set :run, false
set :env, (ENV['RACK_ENV'] ? ENV['RACK_ENV'].to_sym : :development)
set :app_file, File.join(root_dir, 'app', 'mixergyflow.rb')

require 'app/mixergyflow'
run Sinatra.application

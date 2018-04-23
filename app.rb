require 'sinatra' 
require 'sinatra/reloader'
require 'sequel' 
require 'mysql2'
require 'haml'
require 'pry'
require 'pry-byebug' 
require 'yaml'
require 'digest'
require 'slim'
require 'set'
require './sinatra/module_helper'
class Todo < Sinatra::Application # We inherit the Application class of the Sinatra Module
  # We can config every environment, if only this one is present it will work for all
  set :environment, ENV['RACK_ENV'].to_sym
  enable :sessions
  set :session_secret, '123123123123AAA123123123'
  #disable :protection
  set :root, File.dirname(__FILE__)
  set :show_exceptions, :after_handler
  #binding.pry
  # The option below prevents from appearing the error debugging page
  #set :show_exceptions, false
  #disable :raise_errors
  #set :dump_errors, false
  #set :raise_errors, false

  configure :development do
    register Sinatra::Reloader
    
    also_reload 'models/*'
    after_reload do
      puts "Reloaded: #{Time.now}"
    end
  end

  env = 'development'
  var = YAML.load(File.open('config/database.yml'))
  @DB = Sequel.connect(var[environment.to_s])
  #.connect(conn_string, opts = {}, &block) ⇒ Object
  #DB = Sequel.connect("mysql2://root:pass@mysql.getapp.docker/todo") 
  # This way we import our model files located in the models directory. 
  # We get an array of .rb files
  Dir[File.join(File.dirname(__FILE__),'models','*.rb')].each { |model| require model } 
  Dir[File.join(File.dirname(__FILE__),'routes','*.rb')].each { |route| require route }
  # @css_files = []
  # @css_files = Dir[File.join(File.dirname(__FILE__),'public/css','*.css')]
  #binding.pry

end 

# frozen_string_literal: true

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
class Todo < Sinatra::Application
  set :environment, ENV['RACK_ENV'].to_sym
  enable :sessions
  set :session_secret, '123123123123AAA123123123'
  set :root, File.dirname(__FILE__)
  set :show_exceptions, :after_handler

  configure :development do
    register Sinatra::Reloader

    also_reload 'models/*'
    after_reload do
      puts "Reloaded: #{Time.now}"
    end
  end

  var = YAML.safe_load(File.open('config/database.yml'))
  @db = Sequel.connect(var[environment.to_s])

  Dir[File.join(File.dirname(__FILE__), 'models', '*.rb')].each { |model| require model }
  Dir[File.join(File.dirname(__FILE__), 'routes', '*.rb')].each { |route| require route }
end

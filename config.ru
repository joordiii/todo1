# This file is the rackup file. It loads all the gems and the app.rb
# This 2 first lines import the gems
require 'sinatra' # This one includes Sinatra classes and help listening to request
require 'bundler/setup'  # Bundler to manage our gems
# This line check the Gemfile and make sure that all gems ara available and match 
# the version and dependencies met
Bundler.require
#Sets the system environment variable
ENV['RACK_ENV'] = 'development'
# Here we require the main application file
require File.join(File.dirname(__FILE__), 'app.rb')
# The start! method is inherited from Sinatra::Base class. It starts the app and 
# listens for incomming requests
Todo.start! 

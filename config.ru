# frozen_string_literal: true

require 'sinatra' # This one includes Sinatra classes and help listening to request
require 'bundler/setup'
# Bundler to manage our gems

Bundler.require

ENV['RACK_ENV'] = 'development'

require File.join(File.dirname(__FILE__), 'app.rb')

Todo.start!

# frozen_string_literal: true

class Todo < Sinatra::Application
  # sequel queries to test
  get '/test' do
    List[:name]
  end
end

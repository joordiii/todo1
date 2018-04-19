class Todo < Sinatra::Application

  #sequel queries to test
  get '/test' do
    ds = List[:name]
    binding.pry
  end

end
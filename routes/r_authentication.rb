class Todo < Sinatra::Application

  get '/signup/?' do
    title('ToDo App')
    User.count
    if session[:user_id].nil?
      slim :ssignup
    else
      haml :error, locals: {error: 'Please log out first'}
    end
  end
  
  post '/signup/?' do
    md5sum = Digest::MD5.hexdigest params[:password]
    #binding.pry
    User.create(name: params[:name], password: md5sum)
    redirect '/login'
  end 
  
  get '/login/?' do
    title('ToDo App')
    if session[:user_id].nil?
      slim :slogin
    else
      slim :error, locals: {error: 'Please log out first'}
    end
  end
  
  post '/login/?' do
    # validate user credentials
    md5sum = Digest::MD5.hexdigest params[:password]
    @user = User.first(name: params[:name], password: md5sum)
    if @user.nil?
      slim :error, locals: { error: 'Invalid login credentials' }
    else
      @name = params[:name]
      session[:message] = "Successfully stored the name #{@name}."
      session[:user_id] = @user.id
      #binding.pry
      redirect '/'
    end
  end
  
  get '/logout/?' do
    session[:user_id] = nil
    redirect '/login'
  end


end
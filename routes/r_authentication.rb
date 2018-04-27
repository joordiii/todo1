# frozen_string_literal: true

class Todo < Sinatra::Application
  get '/signup/?' do
    title('ToDo App')
    if session[:user_id].nil?
      slim :ssignup
    else
      slim :error, locals: { error: 'Please log out first' }
    end
  end

  post '/signup/?' do
    md5sum = Digest::MD5.hexdigest params[:password]
    @user = User.first(name: params[:name])
    if @user.nil?
      User.create(name: params[:name], password: md5sum, image: params[:image])
      # binding.pry
      redirect '/login'
    else
      slim :ssignup, locals: { errorm: 'Username already exists' }
    end
  end

  get '/login/?' do
    title('ToDo App')
    if session[:user_id].nil?
      slim :slogin
    else
      slim :error, locals: { error: 'Please log out first' }
    end
  end

  post '/login/?' do
    # validate user credentials
    md5sum = Digest::MD5.hexdigest params[:password]
    @user = User.first(name: params[:name], password: md5sum)
    # binding.pry
    if @user.nil?
      slim :slogin, locals: { errorm: 'Invalid login credentials' }
    else
      @name = params[:name]
      @userpic = @user[:image]
      session[:message] = "Successfully stored the name #{@name}."
      session[:user_id] = @user.id
      redirect '/'
    end
  end

  get '/logout/?' do
    session[:user_id] = nil
    redirect '/login'
  end
end

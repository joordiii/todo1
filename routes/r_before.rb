class Todo < Sinatra::Application

  before do # It checks the validity of the user's session. It will be invoked for every route  
    if !['login', 'signup'].include?(request.path_info.split('/')[1]) && session[:user_id].nil?
      redirect '/login'
    end
    # Before every route it sets the @user
    @user = User.first(id: session[:user_id]) if session[:user_id]
  end

end
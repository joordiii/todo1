require 'sinatra' 
#require 'sinatra/reloader'
require 'sequel' 
require 'mysql2'
require 'haml'
require 'pry'
require 'pry-byebug' 
require 'yaml'
require 'digest'
require 'slim'
class Todo < Sinatra::Application # We inherit the Application class of the Sinatra Module
  # We can config every environment, if only this one is present it will work for all
  set :environment, :development #ENV['RACK_ENV']
  enable :sessions
  set :session_secret, 'super secret'
  disable :protection
=begin use Rack::Session::Cookie, 
      :key => 'rack.session',
      :domain => 'myawesomeapp.com',
      :path => '/',
      :expire_after => 2592000,
      :secret => 'random_text',
      :old_secret => 'another_random_text' 
=end
  configure do
    env = 'development'
    var = YAML.load(File.open('config/database.yml'))
    @DB = Sequel.connect(YAML.load(File.open('config/database.yml'))[env])
    #binding.pry
    #.connect(conn_string, opts = {}, &block) ⇒ Object
    #DB = Sequel.connect("mysql2://root:pass@mysql.getapp.docker/todo") 
    # This way we import our model files located in the models directory. 
    # We get an array of .rb files
    Dir[File.join(File.dirname(__FILE__),'models','*.rb')].each { |model| require model } 
  end 
end 

before do # It checks the validity of the user's session. It will be invoked for every route  
  if !['login', 'signup'].include?(request.path_info.split('/')[1]) && session[:user_id].nil?
    #binding.pry
    redirect '/login'
  end
end 


# When typing '/' or '' we get all lists into a variable called all_lists
get '/?' do
  @user = User.first(id: session[:user_id])
  #all_lists =  List.all
  all_lists = List.association_join(:permissions).where(user_id: @user.id)
  #binding.pry
  slim :slists, locals: {lists: all_lists, user: @user}
end
get '/new/?' do
  slim :snew_list
end
post '/new/?' do
  @user = User.first(id: session[:user_id])
  list = List.new_list params[:name], params[:items], @user
  redirect "/lists/#{list.id}"
end

post '/update/?' do
  @user = User.first(id: session[:user_id])
  list_name = params[:lists][0]['name']
  #binding.pry
  #list_name = List.get(:name)
  list_id = params[:lists][0][:id].to_i
  list = List.edit_list list_id, list_name, params[:items], @user
  redirect "http://localhost:4567/lists/#{list_id}"
  #redirect request.referer
end

=begin post '/checked/?'
  @user = User.first(id: session[:user_id])
  list_checked = params[:lists][0]['checked']
  list = List.edit_checked list_checked, @user
end 
=end

post '/delete/?' do
  @user = User.first(id: session[:user_id])
  #binding.pry
  list_id = params["list_id"].to_i
  List.del list_id
  redirect "http://localhost:4567/"
end

get '/lists/:id' do
  @user = User.first(id: session[:user_id])
  all_lists = List.association_join(:permissions).where(user_id: @user.id)
  @list = List.first(id: params[:id])
  slim :slist_details, locals: { lists: all_lists }
end

get '/edit/:id/?' do
  @user = User.first(id: session[:user_id])
  list = List.first(id: params[:id])
  #list2 = List[params[:id]]
  #binding.pry
  can_edit = true

  if list.nil?
    can_edit = false
  elsif list.shared_with == 'public'
    @user = User.first(id: session[:user_id])
    permission = Permission.first(list: list, user: @user)
    if permission.nil? or permission.permission_level == 'read_only'
      can_edit = false
    end
  end

  if can_edit
    slim :sedit_list, locals: {list: list}
  else
    haml :error, locals: {error: 'Invalid permissions'}
  end
end
# Here, we do not require the id to be in the URL as the POST data will have it.
post '/edit/?' do
  @user = User.first(id: session[:user_id])
  List.edit_list params[:id], params[:name], params[:items], @user
  redirect request.referer
end 

post '/permission/?' do
  @user = User.first(id: session[:user_id])
  list = List.first(id: params[:id])
  can_change_permission = true

  if list.nil?
    can_change_permission = false
  elsif list.shared_with != 'public'
    permission = Permission.first(list: list, user: @user)
    if permission.nil? or permission.permission_level == 'read_only'
      can_change_permission = false
    end
  end

  if can_change_permission
    list.permission = params[:new_permissions]
    list.save

    current_permissions = Permission.first(list: list)
    current_permissions.each do |perm|
      perm.destroy
    end

    if params[:new_permissions] == 'private' or parms[:new_permissions] == 'shared'
      user_perms.each do |perm|
        u = User.first(perm[:user])
        Permission.create(list: list, user: u, permission_level: perm[:level], created_at: Time.now, updated_at: Time.now)
      end
    end

    redirect request.referer
  else
    haml :error, locals: {error: 'Invalid permissions'}
  end
end

get '/signup/?' do
  User.count
  if session[:user_id].nil?
    slim :ssignup
  else
    haml :error, locals: {error: 'Please log out first'}
  end
end
  
post '/signup/?' do
  #binding.pry
  md5sum = Digest::MD5.hexdigest params[:password]
  User.create(name: params[:name], password: md5sum)
  redirect '/login'
end 

get '/login/?' do
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
    #redirect "/test?name=#{@name}"
  end
end

get '/logout/?' do
  session[:user_id] = nil
  redirect '/login'
end

get '/test' do
  p "putting user_id"
  p session[:user_id]
  @user = User.first(id: session[:user_id])
  
  @message = session[:message]
  @name = params[:name]
  #binding.pry
  haml :test
end

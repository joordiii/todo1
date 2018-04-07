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
class Todo < Sinatra::Application # We inherit the Application class of the Sinatra Module
  # We can config every environment, if only this one is present it will work for all
  set :environment, :development #ENV['RACK_ENV']
  enable :sessions
  set :session_secret, 'super secret'
  disable :protection
  # The option below prevents from appearing the error debugging page
  #set :show_exceptions, false
  #disable :raise_errors
  set :dump_errors, false
  set :raise_errors, false

  configure do
    register Sinatra::Reloader
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
  enable :reloader
end 

before do # It checks the validity of the user's session. It will be invoked for every route  
  if !['login', 'signup'].include?(request.path_info.split('/')[1]) && session[:user_id].nil?
    redirect '/login'
  end
  # Before every route it sets the @user
  @user = User.first(id: session[:user_id]) if session[:user_id]
end 


# When typing '/' or '' we get all lists into a variable called all_lists
get '/?' do
  all_lists = List.association_join(:permissions).where(user_id: @user.id)
  slim :slists, locals: {lists: all_lists, user: @user}
end
get '/new/?' do
  no_name = false
  no_item_name = false
  list_name = ""
  item_name = ""
  @time_min = Time.now.to_s[0..-16]
  slim :snew_list, locals: {time_now: @time_min, no_name: no_name, no_item_name: no_item_name, list_name: list_name, item_name: item_name}
end
post '/new/?' do
  list_name = params[:name]
  array_items = params[:items]
  no_name = false
  no_item_name = false
  item_name = params[:items][0][:name]
  item_description = params[:items][0][:description]
  due_date = params[:items][0][:due_date]
  ok = 0
  #list = List.new_list params[:name], params[:items], @user
  list = List.new(name: list_name, created_at: Time.now)
  #itemsinstance = Item.new_item params[:name], params[:items], @user
  itemsinstance = params[:items].each_with_index do |elem, index|
    @it = Item.new(name: params[:items][index][:name], description: params[:items][index][:description], created_at: Time.now, updated_at: Time.now, due_date: params[:items][index][:due_date])
    #binding.pry
    case 
      when list.valid? == false && @it.valid? == false
        no_name = true
        no_item_name = true
        list_name = list.name
        item_name = params[:items][index][:name]
        break
      when list.valid? == false && @it.valid? == true
        no_name = true
        no_item_name = false
        list_name = list.name
        item_name = params[:items][index][:name]
        #binding.pry
        break
      when list.valid? == true && @it.valid? == false
        no_name = false
        no_item_name = true
        list_name = list.name
        item_name = params[:items][index][:name]
        break
      else
        no_name = false
        no_item_name = false
        list_name = list.name
        item_name = params[:items][index][:name]
        ok += 1
        #binding.pry
    end
  end
  #If conditions are ok, create the list
  if ok == params[:items].length
    list = List.create_list list_name, array_items, @user
    redirect "/lists/#{list.id}"
  else
    error_list = list.errors
    #binding.pry
    # To prevent errors passing variables to slim
    error_list.empty? ? error_list = {:name=>["","",""]} : error_list = list.errors
    error_items = @it.errors
    #in case of errors render the same form with error messages
    slim :snew_list, locals: {no_name: no_name, no_item_name: no_item_name, 
      list_name: list_name, item_name: item_name, 
      error_list_empty: error_list[:name][0], error_list_format: error_list[:name][1],
      error_list_uniqueness: error_list[2], error_items: error_items[:name][0]} 
    end
end

post '/update/?' do
  list_name = params[:lists][0]['name']
  list_id = params[:lists][0][:id].to_i
  list = List.edit_list list_id, list_name, params[:items], @user
  list_obj = List[id: list_id]
  #binding.pry
  comment_content = params[:comment][:comment]
  Comm.new_comm comment_content, @user, list_obj
  redirect "http://localhost:4567/lists/#{list_id}"
end

post '/delete/?' do
  #binding.pry
  list_id = params["list_id"].to_i
  #List.del list_id
  List.first(id: list_id).destroy
  redirect "http://localhost:4567/"
end

post '/delcomm/?' do
  comm_id = params["comm_id"].to_i
  co = Comm.where(:id => comm_id)
  tcreated = co[:id][:created_at]
  tnow = Time.now
  #binding.pry
  if tnow < tcreated+900
    #Comm.where(:id => comm_id).destroy
    Comm.del_comm comm_id
  end
  redirect "http://localhost:4567/"
end

get '/lists/:id' do
  all_lists = List.association_join(:permissions).where(user_id: @user.id)
  @list = List.first(id: params[:id])
  #binding.pry
  @comms = Comm.where(Sequel.like(:list_id, params[:id]))
  #@comms = Comm.select{|x| x.list_id = params[:id].to_ico}
  #@sorted_list = @list.items.sort_by { |k| k[:checked] ? 0 : 1 }
  #@sorted_list = @list.items_dataset.select_order_map(:checked).reverse
  @sorted_list = @list.items_dataset.order(Sequel.desc(:checked))
  #binding.pry

  slim :slist_details, locals: { lists: all_lists }
end

get '/edit/:id/?' do
  list = List.first(id: params[:id])
  can_edit = true
  time_min = Time.now.to_s[0..-16]
  #binding.pry
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
    slim :sedit_list, locals: { list: list, time_now: time_min }
  else
    haml :error, locals: { error: 'Invalid permissions' }
  end
end
# Here, we do not require the id to be in the URL as the POST data will have it.
post '/edit/?' do
  @user = User.first(id: session[:user_id])
  #binding.pry
  List.edit_list params[:id], params[:name], params[:items], @user 
  redirect request.referer
end 

post '/permission/?' do
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
  end
end

get '/logout/?' do
  session[:user_id] = nil
  redirect '/login'
end


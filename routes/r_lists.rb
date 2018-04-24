# frozen_string_literal: true

class Todo < Sinatra::Application
  # When typing '/' or '' we get all lists into a variable called all_lists
  get '/?' do
    title('All Lists')
    # end_file 'text_file.txt'
    all_lists = List.association_join(:permissions).where(user_id: @user.id)
    slim :slists, locals: { lists: all_lists, user: @user }
    # slim :slists, locals: {lists: all_lists, user: @user}, :layout => :layout2 <- Example using a second layout
  end

  get '/new/?' do
    title('New List')
    # I can pass this two variables to load the js files
    # @js = "/js/jquery-3.3.1.min.js"
    # @js2 = "/js/bootstrap.min.js"
    # or ... I can pass this array, it is the same.
    # @js = ['/js/jquery-3.3.1.min.js', '/js/bootstrap.min.js']
    # or better the sinatra/module_helper.rb that is the one working now
    no_name = false
    no_item_name = false
    list_name = ''
    item_name = ''
    @time_min = Time.now.to_s[0..-16]
    slim :snew_list, locals: { time_now: @time_min, no_name: no_name, no_item_name: no_item_name,
                               list_name: list_name, item_name: item_name }
  end
  post '/new/?' do
    # binding.pry
    list_name = params[:name]
    array_items = params[:items]
    no_name = false
    no_item_name = false
    item_name = params[:items][0][:name]
    item_description = params[:items][0][:description]
    due_date = params[:items][0][:due_date]
    # list = List.new_list params[:name], params[:items], @user
    list = List.new_list list_name
    list.valid?
    returning_values = Item.new_item list, array_items, @user, no_name, no_item_name,
                                     item_name, item_description, due_date
    # If conditions are ok, create the list
    # if returning_values[0] != nil && returning_values[0][0] == params[:items].length
    case returning_values[0]
    when 1
      list = List.create_list list_name, array_items, @user
      redirect "/lists/#{list.id}"
    when 'No errors'
      error_list = list.errors
      error_list2 = Set.new ["Name can't be empty", 'should begin with a character']
      error_list[:name].push('') unless error_list2.include? 'Name shold be unique'
      # To prevent errors passing variables to slim
      # error_list.empty? ? error_list = {:name=>["","",""]} : error_list = list.errors
      error_list = if error_list.empty?
                     { name: ['', '', ''] }
                   else
                     list.errors
                   end
      # returning_values[0][0] = nil ? error_items = "" : error_items = returning_values[0][0]
      error_items = if returning_values[0][0].nil?
                      ''
                    else
                      returning_values[0][0]
                    end
      # error_items.empty? ? error_items = {:name=>[""]} : error_items = returning_values[0].errors
      # in case of errors render the same form with error messages
      slim :snew_list, locals: { no_name: returning_values[1], no_item_name: returning_values[2],
                                 list_name: returning_values[3], item_name: returning_values[4],
                                 error_list_empty: error_list[:name][0], error_list_format: error_list[:name][1],
                                 error_list_uniqueness: error_list[:name][2], error_items: error_items }
    when ["Item can't be empty"]
      error_list = list.errors
      # To prevent errors passing variables to slim
      # error_list.empty? ? error_list = {:name=>["","",""]} : error_list = list.errors
      error_list = if error_list.empty?
                     { name: ['', '', ''] }
                   else
                     list.errors
                   end
      # returning_values[0][0] = nil ? error_items = "" : error_items = returning_values[0][0]
      error_items = if returning_values[0][0].nil?
                      ''
                    else
                      returning_values[0][0]
                    end

      # error_items.empty? ? error_items = {:name=>[""]} : error_items = returning_values[0].errors
      # in case of errors render the same form with error messages
      slim :snew_list, locals: { no_name: returning_values[1], no_item_name: returning_values[2],
                                 list_name: returning_values[3], item_name: returning_values[4],
                                 error_list_empty: error_list[:name][0], error_list_format: error_list[:name][1],
                                 error_list_uniqueness: error_list[:name][2], error_items: error_items }
    end
  end

  post '/update/?' do
    # list_name = params[:lists][0]['name']
    list_id = params[:lists][0][:id].to_i
    # list = List.edit_list list_id, list_name, params[:items], @user
    list_obj = List[id: list_id]
    comment_content = params[:comment][:comment]
    Comm.new_comm comment_content, @user, list_obj
    redirect "http://localhost:4567/lists/#{list_id}"
  end

  post '/delete/?' do
    list_id = params['list_id'].to_i
    # List.del list_id
    List.first(id: list_id).destroy
    redirect 'http://localhost:4567/'
  end

  post '/delcomm/?' do
    comm_id = params['comm_id'].to_i
    co = Comm.where(id: comm_id)
    tcreated = co[:id][:created_at]
    tnow = Time.now
    if tnow < tcreated+900
      # Comm.where(:id => comm_id).destroy
      Comm.del_comm comm_id
    end
    redirect "http://localhost:4567/"
  end

  get '/lists/:id' do
    all_lists = List.association_join(:permissions).where(user_id: @user.id)
    @list = List.first(id: params[:id])
    title("List #{@list.name}")
    # @comms = Comm.where(Sequel.like(:list_id, params[:id]))
    # binding.pry
    @comms = Comm.where(list_id:params[:id])
    # @comms = Comm.select{|x| x.list_id = params[:id].to_ico}
    # @sorted_list = @list.items.sort_by { |k| k[:checked] ? 0 : 1 }
    # @sorted_list = @list.items_dataset.select_order_map(:checked).reverse
    @sorted_list = @list.items_dataset.order(Sequel.desc(:checked))
    slim :slist_details, locals: { lists: all_lists }
  end

  get '/edit/:id/?' do
    list = List.first(id: params[:id])
    can_edit = true
    time_min = Time.now.to_s[0..-16]
    if list.nil?
      can_edit = false
    elsif list.shared_with == 'public'
      @user = User.first(id: session[:user_id])
      permission = Permission.first(list: list, user: @user)
      can_edit = false if permission.nil? || permission.permission_level == 'read_only'
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
    List.edit_list params[:id], params[:name], params[:items], @user 
    redirect request.referer
  end
end

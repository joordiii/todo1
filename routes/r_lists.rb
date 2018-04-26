# frozen_string_literal: true

class Todo < Sinatra::Application
  get '/?' do
    title('All Lists')
    all_lists = List.association_join(:permissions).where(user_id: @user.id)
    slim :slists, locals: { lists: all_lists, user: @user }
    # slim :slists, locals: {lists: all_lists, user: @user}, :layout => :layout2 <- Example using a second layout
  end

  get '/new/?' do
    title('New List')
    @time_min = Time.now.to_s[0..-16]
    due_date = ''

    total_errors = [['', '', ''], [['', '', '', '', '']]]
    first_time = true
    slim :snew_list, locals: { total_errors: total_errors, first_time: first_time, due_date: due_date }
  end
  post '/new/?' do
    list_name = params[:name]
    array_items = params[:items]
    no_name = false
    no_item_name = false
    due_date = params[:items][0][:due_date]
    list = List.new_list list_name
    list.valid?
    list_errors = list.errors
    if list_errors == {}
      full_list_errors = ['', '', '']
    elsif (list_errors[:name].include? "Name can't be empty") && (list_errors[:name].include? 'should begin with a character')
      full_list_errors = list_errors[:name].push('')
    elsif (list_errors[:name].include? 'should begin with a character') && (list_errors[:name].length == 1)
      full_list_errors = list_errors[:name].push('')
      full_list_errors = full_list_errors.unshift('')
    else
      full_list_errors = list_errors[:name].unshift('')
      full_list_errors = full_list_errors.unshift('')
    end
    returning_values = Item.new_item list, array_items, @user, no_name, no_item_name, due_date
    checkingstatus = Item.checkstatus list, array_items, @user, no_name, no_item_name, due_date

    binding.pry
    if checkingstatus == 'ok'
      list = List.create_list list_name, array_items, @user
      # Log.create(user_id: @user.id, list_id: list.id, log_line: "#{list.name.upcase} list created", created_at: Time.now)
      Log.create_log(@user.id, list.id, list.name)
      redirect "/lists/#{list.id}"
    end
    total_errors = []
    total_errors << full_list_errors << returning_values
    first_time = false
    slim :snew_list, locals: { total_errors: total_errors, first_time: first_time, due_date: due_date }
  end

  post '/update/?' do
    List.edit_list params[:lists][0][:id], params[:lists][0][:name], params[:items], @user
    list_id = params[:lists][0][:id].to_i
    list_obj = List[id: list_id]
    comment_content = params[:comment][:comment]
    Comm.new_comm comment_content, @user, list_obj
    redirect "http://localhost:4567/lists/#{list_id}"
  end

  post '/delete/?' do
    list_id = params['list_id'].to_i
    List.first(id: list_id).destroy
    redirect 'http://localhost:4567/'
  end

  post '/delcomm/?' do
    comm_id = params['comm_id'].to_i
    co = Comm.where(id: comm_id)
    tcreated = co[:id][:created_at]
    tnow = Time.now
    Comm.del_comm comm_id if tnow < tcreated + 900
    redirect 'http://localhost:4567/'
  end

  get '/lists/:id' do
    all_lists = List.association_join(:permissions).where(user_id: @user.id)
    @list = List.first(id: params[:id])
    title("List #{@list.name}")
    @comms = Comm.where(list_id: params[:id])
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

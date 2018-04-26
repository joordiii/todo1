# frozen_string_literal: true

class Todo < Sinatra::Application
  post '/permission/?' do
    list = List.first(id: params[:id])
    can_change_permission = true

    if list.nil?
      can_change_permission = false
    elsif list.shared_with != 'public'
      permission = Permission.first(list: list, user: @user)
      can_change_permission = false if permission.nil? || permission.permission_level == 'read_only'
    end

    if can_change_permission
      list.permission = params[:new_permissions]
      list.save

      current_permissions = Permission.first(list: list)
      current_permissions.each(&:destroy)
      perm.destroy

      if params[:new_permissions] == 'private' || parms[:new_permissions] == 'shared'
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
end

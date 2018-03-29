require 'Sequel'

class Comm < Sequel::Model
  set_primary_key :id 
 
  many_to_one :user 
  many_to_one :list 

  def self.new_comm comm, user, list 
    #binding.pry
    Comm.create(comm: comm, user: user, list: list, created_at: Time.now)
  end

  def self.del_comm comm_id, user_id, list_id
    Comm[{comm_id: user_id, user_id: user_id, list_id: list_id }].delete
  end

end
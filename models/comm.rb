require 'Sequel'

class Comm < Sequel::Model
  set_primary_key :id 
 
  many_to_one :user 
  many_to_one :list 

=begin   def before_destroy
    binding.pry
  end 
=end

  def self.new_comm comm, user, list 
    #binding.pry
    if comm != ""
      Comm.create(comm: comm, user: user, list: list, created_at: Time.now, del_date: Time.now+900)
    end
  end

  def self.del_comm comm_id
    #binding.pry
    co = Comm.where(:id => comm_id).delete
  end 

end
require 'Sequel'

class Comm < Sequel::Model
  set_primary_key :id 
 
  many_to_one :user 
  many_to_one :list 

  def self.new_comm comm, user, list 
    #binding.pry
    Comm.create(comm: comm, user: user, list: list, created_at: Time.now, del_date: Time.now+900)
  end

  def self.del_comm comm_id
    #binding.pry
    co = Comm.where(:id => comm_id).delete
  end 


=begin   def self.del_comm comm_id
    #binding.pry
    co = Comm.where(:id => comm_id)
    tcreated = co[:id][:created_at]
    tnow = Time.now
    if tnow > tcreated+900
      Comm.where(:id => comm_id).delete
    end 
  end 
=end

end
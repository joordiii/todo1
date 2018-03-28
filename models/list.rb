require 'sequel' 
Sequel::Model.plugin :validation_helpers 
class List < Sequel::Model 
  set_primary_key :id 
 
  one_to_many :items 
  one_to_many :permissions 
  one_to_many :logs 

  def self.new_list name, items, user
    list = List.create(name: name, created_at: Time.now)
    items.each do |item|
      #binding.pry
      Item.create(name: item[:name], description: item[:description], list: list, user: user, created_at: Time.now, updated_at: Time.now, due_date: item[:due_date])
    end
    Permission.create(list: list, user: user, permission_level: 'read_write', created_at: Time.now, updated_at: Time.now)
    return list
  end

  def self.edit_list id, name, items, user
    #list = List.first(id: id)
    list = List[id: id]
    list.name = name
    #Uncomment the following line after:
    #1.- adding line 9 in 002_create_list_table.rb -> It add the column updated_at
    #list.updated_at = Time.now
    #2.- then do a migration
  
    list.save
    
    items.each do |item|
      if item[:deleted]
        #i = Item.first(item[:id]).destroy
        i = Item[item[:id].to_i]
        next
      end
      #The Sequel::Model.[] is the easiest method to use to find a model 
      #.. instance by its primary key value: ->Item[]<-
      # http://sequel.jeremyevans.net/rdoc/files/doc/querying_rdoc.html
      i = Item[item[:id].to_i]
      #binding.pry  
      if i.nil?
        Item.create(name: item[:name], description: item[:description], list: list, user: user, created_at: Time.now, updated_at: Time.now)
      else
        i.name = item[:name]
        i.description = item[:description]
        i.updated_at = Time.now
        if item[:checked] == nil
          checked_value = 0
        else
          checked_value = 1
        end
        i.checked = checked_value 
        i.due_date = item[:due_date]
        #i.checked = item[:checked].to_i
        i.save
      end
    end
  end

=begin def self.chomp_datetime list
    list = list

    list.save
    
    list.items.each do |item|
      if item[:deleted]
        item[:due_date].to_s.chomp(' +0200')
      end

    end
  end 
=end

  def self.del list_id
    #binding.pry
    # To be able to delete List, I have to delete first the Items and the Permissions
    Item.where(:list_id => list_id).delete
    Permission.where(:list_id => list_id).delete
    List.where(:id => list_id).delete
    #List[list_id].delete
  end
  
  def validate
    super
    validates_presence [:name, :created_at]
    validates_unique :name
    validates_format /\A[A-Za-z]/, :name, message: 'is not a valid name'
  end
end

class Item < Sequel::Model 
  set_primary_key :id 
 
  many_to_one :user 
  many_to_one :list 
end
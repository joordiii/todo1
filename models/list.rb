# frozen_string_literal: true

require 'sequel'
require 'set'
class List < Sequel::Model
  plugin :validation_helpers
  set_primary_key :id
  one_to_many :items
  one_to_many :permissions
  one_to_many :logs
  one_to_many :comms

  def before_destroy
    comms.each(&:destroy)
    items.each(&:destroy)
    permissions.each(&:destroy)
    super
  end

  def self.new_list(name)
    list = List.new(name: name, created_at: Time.now)
    list
  end

  def self.create_list(name, items, user)
    list = List.create(name: name, created_at: Time.now)
    items.each do |item|
      Item.create(name: item[:name], description: item[:description], list: list, user: user,
                  created_at: Time.now, updated_at: Time.now, due_date: item[:due_date])
    end
    Permission.create(list: list, user: user, permission_level: 'read_write',
                      created_at: Time.now, updated_at: Time.now)
    list
  end

  def self.edit_list id, name, items, user
    # list = List.first(id: id)
    list = List[id: id]
    list.name = name
    # Uncomment the following line after:
    # 1.- adding line 9 in 002_create_list_table.rb -> It add the column updated_at
    # list.updated_at = Time.now
    # 2.- then do a migration

    list.save

    items.each do |item|
      if item[:deleted]
        # i = Item.first(item[:id]).destroy
        Item[item[:id].to_i]
        next
      end
      # The Sequel::Model.[] is the easiest method to use to find a model 
      # .. instance by its primary key value: ->Item[]<-
      # http://sequel.jeremyevans.net/rdoc/files/doc/querying_rdoc.html
      i = Item[item[:id].to_i]
      if i.nil?
        Item.create(name: item[:name], description: item[:description], list: list,
                    user: user, created_at: Time.now, updated_at: Time.now)
      else
        i.name = item[:name]
        i.description = item[:description]
        i.updated_at = Time.now
        checked_value = if item[:checked].nil?
                          0
                        else
                          1
                        end
        i.checked = checked_value
        i.due_date = item[:due_date]
        # i.checked = item[:checked].to_i
        i.save
      end
    end
  end

  def validate
    super
    validates_presence [:name], message: "Name can't be empty"
    errors.add(:created_at, 'cannot be empty') unless created_at
    # validates_presence [:name, :created_at]
    validates_unique :name, message: 'Name shold be unique'
    validates_format /\A[A-Za-z]/, :name, message: 'should begin with a character'
  end
end

class Item < Sequel::Model
  plugin :validation_helpers
  set_primary_key :id
  many_to_one :user
  many_to_one :list

  def self.new_item(list, items, _user, no_name, no_item_name, due_date)
    ok = 0
    returning_values =[] 
    # list = List.new(name: name, created_at: Time.now)
    #binding.pry
    items.each_with_index do |_elem, index|
      #binding.pry
      @it = Item.new(name: items[index][:name], description: items[index][:description], created_at: Time.now,
                     updated_at: Time.now, due_date: due_date)
      case list.valid? == true || list.valid? == false
      when list.valid? == false && @it.valid? == false
        single_item_values = []
        no_name = true
        no_item_name = true
        list_name = list[:name]
        item_name = items[index][:name]
        single_item_values << @it.errors[:name][0] << no_name << no_item_name << list_name << item_name
        returning_values << single_item_values
      #binding.pry
      when list.valid? == false && @it.valid? == true
        single_item_values = []
        no_name = true
        no_item_name = false
        list_name = list[:name]
        item_name = items[index][:name]
        @it.errors[:name] = '' if @it.errors[:name].nil?
        single_item_values << @it.errors[:name] << no_name << no_item_name << list_name << item_name
        returning_values << single_item_values
      when list.valid? == true && @it.valid? == false
        single_item_values = []
        no_name = false
        no_item_name = true
        list_name = list[:name]
        item_name = items[index][:name]
        single_item_values << @it.errors[:name][0] << no_name << no_item_name << list_name << item_name
        returning_values << single_item_values
      else
        # no_name = false
        # no_item_name = false
        # item_name = item_name
        # ok += 1
        # return ok
        single_item_values = []
        no_name = false
        no_item_name = false
        list_name = list[:name]
        item_name = items[index][:name]
        @it.errors[:name] = '' if @it.errors[:name].nil?
        single_item_values << @it.errors[:name] << no_name << no_item_name << list_name << item_name
        returning_values << single_item_values
        #binding.pry
      end
    end
    returning_values
  end

  def self.checkstatus(list, items, _user, no_name, no_item_name, due_date)
    returning_values = new_item(list, items, _user, no_name, no_item_name, due_date)
    count = 0
    #binding.pry
    returning_values.each do |elem|
      if elem[3] && elem[4] != ''
        count += 1
      else
        'not valid'
      end
    end
    return 'ok' if count == returning_values.length
    return 'not valid' if count != returning_values.length
    #binding.pry
  end

  def validate
    super
    validates_presence [:name], message: "Item name can't be empty"
    errors.add(:created_at, 'cannot be empty') unless created_at
  end
end

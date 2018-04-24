# frozen_string_literal: true

require 'Sequel'

class Comm < Sequel::Model
  set_primary_key :id
  many_to_one :user
  many_to_one :list

  def self.new_comm(comm, user, list)
    return Comm.create(comm: comm, user: user, list: list, created_at: Time.now, del_date: Time.now + 900) if comm != ''
  end

  def self.del_comm(comm_id)
    Comm.where(id: comm_id).delete
  end
end

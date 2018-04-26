# frozen_string_literal: true

require 'sequel'

class Log < Sequel::Model
  set_primary_key :id
  many_to_one :user
  many_to_one :list

  def self.create_log(user_id, list_id, log_line)
    Log.create(user_id: user_id, list_id: list_id, log_line: "#{log_line.upcase} list created", created_at: Time.now)
  end
end

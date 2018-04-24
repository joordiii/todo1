# frozen_string_literal: true

require 'Sequel'

class Comment < Sequel::Model
  set_primary_key :id
  many_to_one :user
  many_to_one :list

  def self.new_comment(list, user, comment)
    comment = Comment.create(list: list, user: user, comment: comment, created_at: Time.now)
    comment
  end
end

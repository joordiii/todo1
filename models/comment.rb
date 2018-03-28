require 'Sequel'

class Comment < Sequel::Model
  set_primary_key :id

  many_to_one :list
  many_to_one :user

  def self.new_comment list, user, comment
    comment = Comment.create(list: list, user: user, comment: comment, created_at: Time.now)
    return comment
  end

end
# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :items do
      primary_key :id
      String :name, length: 128, null: false
      String :description, length: 256
      foreign_key :user_id, :users, null: false
      foreign_key :list_id, :lists, null: false
      DateTime :created_at
      DateTime :updated_at
      Boolean :checked, default: false
    end
  end
end

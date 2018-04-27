# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:users) { add_column :image, String }
  end
end

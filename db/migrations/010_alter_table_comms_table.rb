# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:comms) { add_column :delete_date, DateTime }
  end
end

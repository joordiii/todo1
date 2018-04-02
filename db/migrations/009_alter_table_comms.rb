Sequel.migration do
  change do
    alter_table(:comms) {add_column :del_date, DateTime}
  end
end 
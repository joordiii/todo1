Sequel.migration do
  change do
    alter_table(:items) {add_column :due_date, DateTime}
  end
end
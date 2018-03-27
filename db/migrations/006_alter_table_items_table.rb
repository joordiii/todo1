Sequel.migration do
  alter_table do
    add_column :due_date, DateTime
    from(:items)
  end
end
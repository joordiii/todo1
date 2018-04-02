Sequel.migration do
  change do
    create_table :comms do
      primary_key :id
      String :comm, :length => 256
      foreign_key :user_id, :users, :null => false
      foreign_key :list_id, :lists, :null => false
      DateTime :created_at
    end
  end
end 

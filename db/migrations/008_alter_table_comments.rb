Sequel.migration do
  change do
    alter_table(:comments) {add_primary_key [:user_id, :list_id], :name => :comments_pk}
  end
end 
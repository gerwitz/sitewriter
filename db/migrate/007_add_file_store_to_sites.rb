Sequel.migration do
  change do
    alter_table(:sites) do
      add_column :file_store_id, Integer
    end
  end
end

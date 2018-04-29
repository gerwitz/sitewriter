Sequel.migration do
  change do
    alter_table(:sites) do
      add_column :file_flow_id, Integer
    end
  end
end

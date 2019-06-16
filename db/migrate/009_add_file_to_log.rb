Sequel.migration do
  change do
    alter_table(:log) do
      add_column :file, String, size: 255
    end
  end
end

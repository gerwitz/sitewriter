Sequel.migration do
  change do
    alter_table(:log) do
      add_column :photos, String, text:true
    end
  end
end

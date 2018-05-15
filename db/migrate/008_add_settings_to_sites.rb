Sequel.migration do
  change do
    alter_table(:sites) do
      add_column :timezone, String, size: 255, default: 'Etc/UTC'
      add_column :private, TrueClass, default: true
      add_column :generator, String, size: 255
    end
  end
end

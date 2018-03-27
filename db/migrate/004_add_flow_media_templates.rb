Sequel.migration do
  change do
    alter_table(:flows) do
      add_column :media_path_template, String, size: 255
      add_column :media_url_template, String, size: 255
    end
  end
end

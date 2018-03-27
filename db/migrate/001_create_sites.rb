Sequel.migration do
  change do
    create_table(:sites) do
      primary_key :id
      String :domain, null: false
      String :url
    end
  end
end

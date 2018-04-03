Sequel.migration do
  change do
    create_table(:log) do
      primary_key :id
      foreign_key :site_id, :sites
      foreign_key :flow_id, :flows

      column :started_at, 'timestamp without time zone', index: true
      column :finished_at, 'timestamp without time zone'
      column :request, :jsonb
      String :kind
      String :url, size: 255
      Integer :response_code
      column :error, :jsonb
    end
  end
end

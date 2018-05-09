class Site < Sequel::Model
  many_to_one :default_store, class: :Store
  many_to_one :file_flow, class: :Flow
  one_to_many :flows

  def log(count=20)
    return DB[:log].where(site_id: id).reverse_order(:started_at).first(count)
  end
end

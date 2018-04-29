class Site < Sequel::Model
  one_to_one :default_store, class: :Store
  one_to_one :file_flow, class: :Flow
  one_to_many :flows

  def log
    return DB[:log].where(site_id: id).first(20)
  end
end

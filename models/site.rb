class Site < Sequel::Model
  one_to_many :stores
  one_to_many :flows

  def log
    return DB[:log].where[site_id: @id]
  end
end

class Store < Sequel::Model

  TYPES = {
    1 => :Github
  }

  plugin :single_table_inheritance, :type_id, model_map: TYPES

  many_to_one :site

  def type_desc
    return "Unknown"
  end

  def name
    return "Invalid"
  end

end

class StoreError < SitewriterError
  def initialize(message)
    super("store", message)
  end
end

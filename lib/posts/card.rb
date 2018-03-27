class Card < Post

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def type_id
    TYPES.key(:card)
  end

  def h_type
    'h-card'
  end

  def generate_url
    generate_url_slug('/card/')
  end

end

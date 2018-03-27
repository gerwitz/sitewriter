class Event < Post

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def type_id
    TYPES.key(:event)
  end

  def h_type
    'h-event'
  end

  def generate_url
    generate_url_published
  end

end

class Event < Post

  # TODO

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'event'
  end

end

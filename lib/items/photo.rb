class Photo < Post

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'photo'
  end

end

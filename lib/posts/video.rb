class Video < Post

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'video'
  end

end

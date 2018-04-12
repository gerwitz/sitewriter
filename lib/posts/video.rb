class Video < Post

  VARIABLES_CATALOG = {
  }

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'video'
  end

end

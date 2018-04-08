class Photo < Post

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'audio'
  end

end

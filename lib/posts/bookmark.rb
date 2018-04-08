class Bookmark < Post

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'bookmark'
  end

end

class Repost < Post

  # TODO

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'repost'
  end

end

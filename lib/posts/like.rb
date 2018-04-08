class Like < Post

  # TODO

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'like'
  end

end

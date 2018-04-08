class Reply < Post

  # TODO

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'reply'
  end

end

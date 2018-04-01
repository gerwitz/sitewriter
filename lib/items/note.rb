class Note < Post

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'note'
  end

end

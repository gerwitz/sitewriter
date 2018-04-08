class Checkin < Post

  # TODO

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'checkin'
  end

end

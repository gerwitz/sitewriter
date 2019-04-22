class Photo < Post

  VARIABLES_CATALOG = {
    syndication: 'Original URL'
  }

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'photo'
  end

  def render_variables
    return super().merge({
      syndication: @syndication
    })
  end

end

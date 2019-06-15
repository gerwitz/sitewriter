class Like < Post

  VARIABLES_CATALOG = {
    like_of: 'URL',

    has_photos: nil,
    photos: nil

  }

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'like'
  end

  def render_variables
    return super().merge({
      like_of: @like_of
    })
  end

end

class Like < Post

  VARIABLES_CATALOG = {
    like_of: 'liked URL',

    content: nil,
    has_photos: nil,
    photos: nil

  }

  def initialize(properties, url=nil)
    super(properties, url)
    if properties.key?('like-of')
      @like_of = properties['like-of'][0]
    else
      @like_of = ''
    end
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

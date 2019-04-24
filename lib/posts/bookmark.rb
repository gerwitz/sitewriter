class Bookmark < Post

  VARIABLES_CATALOG = {
    name: 'bookmark name',
    url: 'bookmarked url'
  }

  def initialize(properties, url=nil)
    super(properties, url)
  end

  def kind
    'bookmark'
  end

  def render_variables
    return super().merge({
      name: @name,
      url: @bookmark_url
    })
  end

end

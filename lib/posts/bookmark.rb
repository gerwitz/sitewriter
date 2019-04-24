class Bookmark < Post

  VARIABLES_CATALOG = {
    title: 'bookmark title',
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
      title: @title,
      url: @url
    })
  end

end

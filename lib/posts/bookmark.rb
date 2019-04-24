class Bookmark < Post

  VARIABLES_CATALOG = {
    name: 'bookmark name',
    url: 'bookmarked url'
  }

  def initialize(properties, url=nil)
    super(properties, url)
    if properties.key?('name')
      @name = properties['name'][0]
    else
      @name = ''
    end
    if properties.key?('bookmark-of')
      @url = properties['bookmark-of'][0]
    else
      @url = ''
    end
  end

  def kind
    'bookmark'
  end

  def render_variables
    return super().merge({
      name: @name,
      url: @url
    })
  end

end

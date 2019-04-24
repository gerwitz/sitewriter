class Article < Post

  VARIABLES_CATALOG = {
    title: 'post title'
  }

  attr_accessor :title

  def initialize(properties, url=nil)
    super(properties, url)
    if properties.key?('name')
      @title = properties['name'][0]
    else
      @title = ''
    end
  end

  def kind
    'article'
  end

  def render_variables
    return super().merge({
      title: @title
    })
  end

end

class Article < Post

  VARIABLES_CATALOG = {
    title: 'Post Title'
  }

  attr_accessor :title

  def initialize(properties, url=nil)
    super(properties, url)
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

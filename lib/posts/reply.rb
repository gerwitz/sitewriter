class Reply < Post

  VARIABLES_CATALOG = {
    original_url: 'original post URL',
    title: 'title',

    has_photos: nil,
    photos: nil
  }

  def initialize(properties, url=nil)
    super(properties, url)
    if properties.key?('in-reply-to')
      @original_url = properties['in-reply-to'][0]
    else
      @original_url = ''
    end
    if properties.key?('name')
      @title = properties['name'][0]
    else
      @title = ''
    end
  end

  def kind
    'reply'
  end

  def render_variables
    return super().merge({
      original_url: @original_url,
      title: @title
    })
  end

end

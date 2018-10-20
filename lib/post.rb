class Post
  require 'yaml'

  TYPES_CATALOG = YAML.load_file(File.join(__dir__, 'post_types.yml'))

  TYPES = TYPES_CATALOG.keys

  VARIABLES_CATALOG = {
    content: 'post content',
    slug: 'post slug (using hyphens)',
    slug_underscore: 'post slug (using underscores)',
    date_time: 'full publication time (rfc3339 format)',
    year: 'publication year (YYYY)',
    month: 'publication month (01-12)',
    day: 'day of publication month (01-31)',
    hour: 'hour of publication (00-23)',
    year_month: 'year and month (YYYY-MM)',
    minute: 'minute of publication',
    second: 'second of publication',
    categories: 'list of categories (a.k.a. tags)',
    # first_category: 'the first catagory',
    has_photos: 'true if there are any photo attachments',
    photos: 'list of attached photos'
  }

  # this was for access to the raw microformat properties
  # ...but maybe we can avoid that
  # attr_reader :properties, :url

  def initialize(properties, url=nil)
    @properties = properties
    @url = url
    if @properties.key?('category')
      @categories = @properties['category']
    else
      @categories = []
    end
    @photos = []

    unless @properties.key?('published')
      # This shouldn't happen anymore
      @properties['published'] = [Time.now.utc.iso8601]
    end
  end

  def kind
    "unknown"
  end

  def attach_url(type, url)
    case type
    when :photo
      @photos << {url: url}
    else
      raise "Unknown URL type #{type}"
    end
  end

  def timify
    published = @properties['published'].first
    return DateTime.iso8601(published)
  end

  # memoize
  def time
    @time ||= timify
  end

  def render_variables
    return {
      slug: slug,
      slug_underscore: slug_underscore,
      date_time: time.rfc3339,
      year: time.strftime('%Y'),
      month: time.strftime('%m'),
      day: time.strftime('%d'),
      hour: time.strftime('%H'),
      minute: time.strftime('%M'),
      second: time.strftime('%S'),
      year_month: time.strftime('%Y-%m'),
      categories: @categories,
      # first_category: @categories.first || '',
      content: content,
      has_photos: @photos.any?,
      photos: @photos
    }
    # }.merge(@properties)
  end

  # memoize
  def slug
    @slug ||= slugify('-')
  end

  # memoize
  def slug_underscore
    @slug_underscore ||= slugify('_')
  end

  def content
    if @properties.key?('content')
      if @properties['content'][0].is_a?(Hash) &&
          @properties['content'][0].key?('html')
        @properties['content'][0]['html']
      else
        @properties['content'][0]
      end
    elsif @properties.key?('summary')
      @properties['summary'][0]
    end
  end

  def slugify(spacer='-')
    @raw_slug ||= slugify_raw
    if @raw_slug.empty?
      return time.strftime("%d#{spacer}%H%M%S")
    else
      return @raw_slug.downcase.gsub(/[^\w-]/, ' ').strip.gsub(' ', spacer).gsub(/[-_]+/,spacer).split(spacer)[0..5].join(spacer)
    end
  end

  def slugify_raw
    content = ''
    if @properties.key?('name')
      content = @properties['name'][0]
    end
    if content.empty? && @properties.key?('summary')
      content = @properties['summary'][0]
    end
    if content.empty? && @properties.key?('content')
      if @properties['content'][0].is_a?(Hash) && @properties['content'][0].key?('html')
         content = @properties['content'][0]['html']
       else
         content = @properties['content'][0]
       end
    end
    return content
  end

  # def replace(props)
  #   props.keys.each do |prop|
  #     @properties[prop] = props[prop]
  #   end
  # end
  #
  # def add(props)
  #   props.keys.each do |prop|
  #     unless @properties.key?(prop)
  #       @properties[prop] = props[prop]
  #     else
  #       @properties[prop] += props[prop]
  #     end
  #   end
  # end
  #
  # def remove(props)
  #   if props.is_a?(Hash)
  #     props.keys.each do |prop|
  #       @properties[prop] -= props[prop]
  #       if @properties[prop].empty?
  #         @properties.delete(prop)
  #       end
  #     end
  #   else
  #     props.each do |prop|
  #       @properties.delete(prop)
  #     end
  #   end
  # end
  #
  # def delete
  #   @properties['deleted'] = [Time.now.utc.iso8601]
  # end
  #
  # def undelete
  #   @properties.delete('deleted')
  # end
  #
  # def set_updated
  #   @properties['updated'] = [Time.now.utc.iso8601]
  # end

  def set_slug(mp_params)
    if mp_params.key?('properties')
      return unless mp_params['properties'].key?('mp-slug')
      mp_slug = mp_params['properties']['mp-slug'][0]
    else
      return unless mp_params.key?('mp-slug')
      mp_slug = mp_params['mp-slug']
    end
    @slug = mp_slug.strip.downcase.gsub(/[^\w-]/, '-')
  end

  def syndicate(services)
    # only syndicate if this is an entry or event
    return unless ['h-entry','h-event'].include?(h_type)

    # iterate over the mp-syndicate-to services
    new_syndications = services.map { |service|
      # have we already syndicated to this service?
      unless @properties.key?('syndication') &&
          @properties['syndication'].map { |s|
            s.start_with?(service)
          }.include?(true)
        Syndication.send(self, service)
      end
    }.compact

    return if new_syndications.empty?
    # add to syndication list
    @properties['syndication'] ||= []
    @properties['syndication'] += new_syndications
  end

  def self.class_for_type(type = :unknown)
    class_name = TYPES_CATALOG.dig(type.to_s, 'class').to_s
    if Object.const_defined?(class_name)
      return Object.const_get(class_name)
    else
      return Post
    end
  end

  def self.new_for_type(type, props)
    klass = class_for_type(type)
    return klass.new(props)
  end

  # derived from: https://indieweb.org/post-type-discovery
  # see README for a description
  def self.type_from_properties(props)
    post_type = ''
    mf_type = ''
    if props.key?('type')
      mf_type = props['type'][0].to_s
      if mf_type == 'h-event'
        post_type = :event
      elsif mf_type == 'h-entry'
        if props.key?('in-reply-to')
          post_type = :reply
        elsif props.key?('repost-of')
          post_type = :repost
        elsif props.key?('bookmark-of')
          post_type = :bookmark
        elsif props.key?('checkin') || props.key?('u-checkin')
          post_type = :checkin
        elsif props.key?('like-of')
          post_type = :like
        elsif props.key?('video')
          post_type = :video
        elsif props.key?('photo')
          post_type = :photo
        else
          # does it have a title?
          if props.key?('name')
            title = props['name'][0]
            if title.empty?
              post_type = :note
            else
              post_type = :article
            end
          else
            post_type = :note
          end
        end
      end
    end
    return post_type
  end

  # def self.class_from_type(type)
  #   case type
  #   when 'h-card'
  #     Card
  #   when 'h-cite'
  #     Cite
  #   when 'h-entry'
  #     Entry
  #   when 'h-event'
  #     Event
  #   end
  # end

  def self.description_for_type(type = :unknown)
    "<p>#{TYPES_CATALOG[type.to_s]['description']}</p> <a href=\"#{TYPES_CATALOG[type.to_s]['link']}\">Read more.</a>"
  end

  def self.variables_for_type(type)
    class_for_type(type)::VARIABLES_CATALOG.merge(VARIABLES_CATALOG)
  end

  def self.valid_types
    %w( h-card h-cite h-entry h-event )
  end

end

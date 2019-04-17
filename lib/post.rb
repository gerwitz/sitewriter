class Post
  require 'yaml'

  TYPES_CATALOG = YAML.load_file(File.join(__dir__, 'post_types.yml'))

  TYPES = TYPES_CATALOG.keys

  VARIABLES_CATALOG = {
    content: 'post content',

    slug: 'post slug (using hyphens)',
    slug_underscore: 'post slug (using underscores)',

    utc_datetime: 'publication time in UTC (RFC 3339 format)',
    utc_epoch: 'publication time as seconds since 1970-01-01',

    datetime: 'publication time (RFC 3339 format)',
    date: 'publication date (YYYY-MM-DD)',
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
    # photos_urls: 'list of attached photos'
    # photos_markdown: 'list of attached photos'
    # photos_html: 'list of attached photos'
  }

  def initialize(properties, timezone: nil)
    @properties = properties
    @timezone = timezone

    if @properties.key?('category')
      @categories = @properties['category']
    else
      @categories = []
    end
    @photos = []
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

  # get publication time as a DateTime and apply timezone
  def timify
    # no client sends 'published' but we'll prepare for it
    if @properties.key?('published')
      utc_time = Time.iso8601(@properties['published'].first)
    else
      utc_time = Time.now.utc
    end
    if @timezone
      # local_time = @timezone.utc_to_local(utc_time)
      utc_total_offset = @timezone.period_for_utc(utc_time).utc_total_offset
      local_time = utc_time.getlocal(utc_total_offset)
    else
      local_time = utc_time
    end

    return {local: local_time, utc: utc_time}
  end
  # memoize
  def both_times
    @times ||= timify
  end
  def local_time
    both_times[:local]
  end
  def utc_time
    both_times[:utc]
  end

  # TODO memoize this
  def render_variables
    return {
      slug: slug,
      slug_underscore: slug_underscore,

      utc_datetime: utc_time.to_datetime.rfc3339,
      utc_epoch: utc_time.to_i,

      datetime: local_time.strftime('%Y-%m-%dT%H:%M:%S%:z'),
      date: local_time.strftime('%Y-%m-%d'),
      year: local_time.strftime('%Y'),
      month: local_time.strftime('%m'),
      day: local_time.strftime('%d'),
      hour: local_time.strftime('%H'),
      minute: local_time.strftime('%M'),
      second: local_time.strftime('%S'),
      year_month: local_time.strftime('%Y-%m'),

      categories: @categories,
      # first_category: @categories.first || '',

      content: content,

      has_photos: @photos.any?,
      photos: @photos,
      # photos_urls: @photos.map(|p| p[:url])
      # photos_markdown: @photos.map(|p| "![](#{p[:url]}")
      # photos_html: @photos.map(|p| "<img src=\"#{p[:url]}\">")
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

  def self.new_for_type(type, props, timezone=nil)
    klass = class_for_type(type)
    return klass.new(props, timezone: timezone)
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

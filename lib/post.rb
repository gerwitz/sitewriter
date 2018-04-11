class Post
  require 'yaml'

  TYPES_CATALOG = YAML.load_file(File.join(__dir__, 'post_types.yml'))

  TYPES = TYPES_CATALOG.keys

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
      date_time: time.rfc3339,
      year: time.strftime('%Y'),
      month: time.strftime('%m'),
      day: time.strftime('%d'),
      categories: @categories,
      first_category: @categories.first || '',
      content: content,
      has_photos: @photos.any?,
      photos: @photos
    }
    # }.merge(@properties)
  end

  # def data
  #   { 'type' => [h_type], 'properties' => @properties }
  # end

  # def filename
  #   "#{url}.json"
  # end

  def slug
    @slug ||= slugify
  end

  # def url
  #   @url ||= generate_url
  # end
  #
  # def absolute_url
  #   URI.join(ENV['SITE_URL'], url).to_s
  # end

  # def is_deleted?
  #   @properties.key?('deleted') &&
  #     Time.parse(@properties['deleted'][0]) < Time.now
  # end

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

  # def generate_url_published
  #   # unless @properties.key?('published')
  #   #   @properties['published'] = [Time.now.utc.iso8601]
  #   # end
  #   "/#{Time.parse(@properties['published'][0]).strftime('%Y/%m')}/#{slug}"
  # end
  #
  # def generate_url_slug(prefix='/')
  #   slugify_url = Utils.slugify_url(@properties['url'][0])
  #   "#{prefix}#{slugify_url}"
  # end

  def slugify
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
    if content.empty?
      return time.strftime('%d-%H%M%S')
    else
      content.downcase.gsub(/[^\w-]/, ' ').strip.gsub(' ', '-').gsub(/[-_]+/,'-').split('-')[0..5].join('-')
    end
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

  def self.new_for_type(type, props)
    class_name = TYPES_CATALOG.dig(type.to_s, 'class').to_s
    puts "👑 #{class_name}"
    if Object.const_defined?(class_name)
      klass = Object.const_get(class_name)
    else
      klass = Post
    end
    puts "👑 #{klass}"
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
        if find_values(props, 'in-reply-to').any?
          post_type = :reply
        elsif find_values(props, 'repost-of').any?
          post_type = :repost
        elsif find_values(props, 'bookmark-of').any?
          post_type = :bookmark
        elsif find_values(props, 'checkin').any? || find_values(props, 'u-checkin').any?
          post_type = :checkin
        elsif find_values(props, 'like-of').any?
          post_type = :like
        elsif find_values(props, 'video').any?
          post_type = :video
        elsif find_values(props, 'photo').any?
          post_type = :photo
        else
          # does it have a title?
          if find_values(props, 'name').any?
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

  def self.valid_types
    %w( h-card h-cite h-entry h-event )
  end

private

  def self.find_values(props, key)
    return props.reduce([]){ |memo, prop|
      if prop.has_key?(key)
        memo << prop[key]
      end
    }
  end

end

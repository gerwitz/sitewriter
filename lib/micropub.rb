module Micropub
  module_function # why?

  # TODO: handle JSON requests
  def create(params, timezone=nil)
    if params.key?('h')
      # form-encoded
      mf_type = 'h-'+params['h'].to_s
      safe_properties = sanitize_properties(params)
      services = params.key?('mp-syndicate-to') ?
        Array(params['mp-syndicate-to']) : []
    elsif params.key?('type') && params['type'].is_a?(Array)
      # JSON
      mf_type = params['type'][0].to_s
      safe_properties = sanitize_properties(params['properties'])
      services = params['properties'].key?('mp-syndicate-to') ?
        params['properties']['mp-syndicate-to'] : []
      # check_if_syndicated(params['properties'])
    end
    safe_properties['type'] = [mf_type]
    # wrap each non-array value in an array
    deep_props = Hash[ safe_properties.map { |k, v| [k, Array(v)] } ]
    puts "👑 deep_props: #{deep_props.inspect}"
    post_type = Post.type_from_properties(deep_props)
    puts "👑 post_type: #{post_type}"
    post = Post.new_for_type(post_type, deep_props, timezone)
    # puts "👑 post: #{post.inspect}"

    post.set_explicit_slug(params)
    # post.syndicate(services) if services.any?
    # Store.save(post)
    return post
  end

  def create_media(params)
    # puts "🖼 #{params}"
    return Media.new(params)
  end

  def action(properties)
    post = Store.get_url(properties['url'])

    case properties['action'].to_sym
    when :update
      if properties.key?('replace')
        verify_hash(properties, 'replace')
        post.replace(properties['replace'])
      end
      if properties.key?('add')
        verify_hash(properties, 'add')
        post.add(properties['add'])
      end
      if properties.key?('delete')
        verify_array_or_hash(properties, 'delete')
        post.remove(properties['delete'])
      end
    when :delete
      post.delete
    when :undelete
      post.undelete
    end

    if properties.key?('mp-syndicate-to') && properties['mp-syndicate-to'].any?
      post.syndicate(properties['mp-syndicate-to'])
    end
    post.set_updated
    Store.save(post)
  end

  def verify_hash(properties, key)
    unless properties[key].is_a?(Hash)
      raise InvalidRequestError.new(
        "Invalid request: the '#{key}' property should be a hash.")
    end
  end

  def verify_array_or_hash(properties, key)
    unless properties[key].is_a?(Array) || properties[key].is_a?(Hash)
      raise InvalidRequestError.new(
        "Invalid request: the '#{key}' property should be an array or hash.")
    end
  end

  # has this post already been syndicated, perhaps via a pesos method?
  # def check_if_syndicated(properties)
  #   if properties.key?('syndication') &&
  #       Cache.find_via_syndication(properties['syndication']).any?
  #     raise ConflictError.new
  #   end
  # end

  def sanitize_properties(properties)
    Hash[
      properties.map { |k, v|
        unless k.start_with?('mp-') || k == 'access_token' || k == 'h' ||
            k == 'syndicate-to'
          [k, v]
        end
      }.compact
    ]
  end

  class ForbiddenError < SitewriterError
    def initialize(message="The authenticated user does not have permission to perform this request.")
      super("forbidden", message, 403)
    end
  end

  class InsufficientScopeError < SitewriterError
    def initialize(message="The scope of this token does not meet the requirements for this request.")
      super("insufficient_scope", message, 401)
    end
  end

  class InvalidRequestError < SitewriterError
    def initialize(message="The request is missing a required parameter, or there was a problem with a value of one of the parameters.")
      super("invalid_request", message, 400)
    end
  end

  class TypeError < SitewriterError
    def initialize(message="The request did not match any known post type.")
      super("server_error", message, 422)
    end
  end

  # not on-spec but it feels right
  class ContentError < SitewriterError
    def initialize(message="The request includes content that cannot be accepted for writing.")
      super("unaccepted_content", message, 422)
    end
  end

  class NotFoundError < SitewriterError
    def initialize(message="The post with the requested URL was not found.")
      super("not_found", message, 400)
    end
  end

  class ConflictError < SitewriterError
    def initialize(
        message="The post has already been created and syndicated.")
      super("conflict", message, 409)
    end
  end

end

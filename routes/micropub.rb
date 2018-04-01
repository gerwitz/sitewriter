class SiteWriter < Sinatra::Application

  post '/:domain/micropub' do
    # TODO: handle multipart requests
    puts "Micropub params=#{params}"
    site = find_site
    flows = site.flows_dataset
    # start by assuming this is a non-create action
    # if params.key?('action')
    #   verify_action
    #   require_auth
    #   verify_url
    #   post = Micropub.action(params)
    #   status 204
    # elsif params.key?('file')
    if params.key?('file')
      # assume this a file (photo) upload
      require_auth
      media = Media.new(params[:file])
      flow = flows.first(allow_media: true)
      url = flow.store_file(media)
      headers 'Location' => url
      status 202
    else
      # assume this is a create
      require_auth
      verify_create
      post = Micropub.create(params)
      raise Micropub::InvalidRequestError.new(
        "Unknown post kind."
      ) unless post
      flow = flows.where(post_kind: post.kind).first
      raise Micropub::ContentError.new(
        "Not configured to write posts of kind '#{post.kind}'."
      ) unless flow

      if params.key?(:photo)
        flow.attach_photos(post, params[:photo])
      end

      url = flow.store_post(post)
      headers 'Location' => url
      status 202
    end
  end

  # TODO: syndication targets
  get '/:domain/micropub' do
    site = find_site
    if params.key?('q')
      require_auth
      content_type :json
      case params[:q]
      when 'source'
        verify_url
        render_source
      when 'config'
        {
          "media-endpoint" => "#{request.scheme}://#{request.host_with_port}/#{site.domain}/micropub",
          "syndicate-to" => []
        }.to_json
      when 'syndicate-to'
        "[]"
      else
        # Silently fail if query method is not supported
      end
    else
      'Micropub endpoint'
    end
  end

private

  def require_auth
    return unless settings.production?
    token = request.env['HTTP_AUTHORIZATION'] || params['access_token'] || ""
    token.sub!(/^Bearer /,'')
    if token.empty?
      raise Auth::NoTokenError.new
    end
    scope = params.key?('action') ? params['action'] : 'post'
    Auth.verify_token_and_scope(token, scope)
  end

  def verify_create
    if params.key?('h') && Post.valid_types.include?("h-#{params[:h]}")
      return
    elsif params.key?('type') && Post.valid_types.include?(params[:type][0])
      return
    else
      raise Micropub::InvalidRequestError.new(
        "You must specify a Microformats 'h-' type to create a new post. " +
        "Valid post types are: #{Post.valid_types.join(' ')}."
      )
    end
  end

  def verify_action
    valid_actions = %w( create update delete undelete )
    unless valid_actions.include?(params[:action])
      raise Micropub::InvalidRequestError.new(
        "The specified action ('#{params[:action]}') is not supported. " +
        "Valid actions are: #{valid_actions.join(' ')}."
      )
    end
  end

  # def verify_url
  #   unless params.key?('url') && !params[:url].empty? &&
  #       Store.exists_url?(params[:url])
  #     raise Micropub::InvalidRequestError.new(
  #       "The specified URL ('#{params[:url]}') could not be found."
  #     )
  #   end
  # end

  # def render_syndication_targets
  #   content_type :json
  #   {}.to_json
  # end

  # def render_config
  #   content_type :json
  #   {
  #     "media-endpoint" => "#{ENV['SITE_URL']}micropub",
  #     "syndicate-to" => settings.syndication_targets
  #   }.to_json
  # end

  # this is probably broken now
  def render_source
    content_type :json
    relative_url = Utils.relative_url(params[:url])
    not_found unless post = Store.get("#{relative_url}.json")
    data = if params.key?('properties')
      properties = {}
      Array(params[:properties]).each do |property|
        if post.properties.key?(property)
          properties[property] = post.properties[property]
        end
      end
      { 'type' => [post.h_type], 'properties' => properties }
    else
      post.data
    end
    data.to_json
  end

end

class SiteWriter < Sinatra::Application

  post '/:domain/micropub/?' do
    # TODO: handle multipart requests
    site = find_site
    start_log(site)
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
      @log[:request] = "#{request.media_type} (#{request.content_length} bytes)"
      require_auth
      media = Micropub.create_media(params[:file])
      @log[:kind] = 'file'
      flow = site.file_flow
      @log[:flow_id] = flow.id
      @log[:file] = flow.file_path_for_media(media)
      url = flow.store_file(media)
      @log[:url] = url
      @log[:status_code] = 202
      write_log
      headers 'Location' => url
      status 202
    else
      # assume this is a create
      request.body.rewind
      @log[:request] = request.body.read.dump
      require_auth
      site_tz = TZInfo::Timezone.get(site.timezone) || TZInfo::Timezone.get('UTC')
      # @log[:timezone] = site_tz.identifier
      post = Micropub.create(params, site_tz)
      raise Micropub::TypeError.new unless post
      @log[:kind] = post.kind
      flow = flows.where(post_kind: post.kind).first
      raise Micropub::ContentError.new(
        "Not configured to write posts of kind '#{post.kind}'."
      ) unless flow
      @log[:flow_id] = flow.id
      if params.key?(:photo)
        photo_urls = handle_photos(flow, post, params[:photo])
        @log[:photos] = photo_urls
      end
      @log[:file] = flow.file_path_for_post(post)
      url = flow.store_post(post)
      @log[:url] = url
      @log[:status_code] = 202
      write_log
      headers 'Location' => url
      status 202
    end
  end

  # TODO: syndication targets
  get '/:domain/micropub/?' do
    site = find_site
    # start_log(site)
    if params.key?('q')
      require_auth
      content_type :json
      case params[:q]
      when 'source'

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

  error SitewriterError do
    e = env['sinatra.error']
    json = {
      error: e.type,
      error_description: e.message
    }.to_json
    if @log.is_a? Hash
      @log[:status_code] = e.status
      @log[:error] = Sequel.pg_json(json)
      write_log
    end
    halt(e.status, { 'Content-Type' => 'application/json' }, json)
  end

  # error do
  #   e = env['sinatra.error']
  #   error_description = "Unexpected server error (#{e.class})."
  #   if @log.is_a? Hash
  #     error_description << " Details can be found in your activity log."
  #     @log[:status_code] = 500
  #     log_json = {
  #       error: e.class,
  #       error_description: e.message,
  #       backtrace: e.backtrace
  #     }.to_json
  #     @log[:error] = Sequel.pg_json(log_json)
  #     write_log
  #   end
  #   json = {
  #     error: 'server_error',
  #     error_description: error_description
  #   }.to_json
  #   halt(500, { 'Content-Type' => 'application/json' }, json)
  # end

private

  def handle_photos(flow, post, params)
    urls = []
    if params.is_a?(Array)
      urls = params.map.with_index do |item, index|
        if item.is_a?(Array)
          handle_photos(flow, post, item)
        else
          puts "🖼🖼 #{item}"
          if valid_url?(item)
            flow.attach_photo_url(post, item)
          else
            media = Micropub.create_media(item)
            flow.attach_photo_media(post, media)
          end
        end
      end
    else
      puts "🖼🖼 #{params}"
      if valid_url?(params)
        flow.attach_photo_url(post, params)
      else
        media = Micropub.create_media(params)
        media.post_slug = post.slug
        flow.attach_photo_media(post, media)
      end
    end
    return urls
  end

  def valid_url?(url)
    puts "Is this a URL? #{url} "
    begin
      uri = URI.parse(url)
      puts "YES!\n"
      return true
    rescue URI::InvalidURIError
      puts "NO.\n"
      return false
    end
  end

  def start_log(site)
    # DB is defined in models/init
    @log = {
      started_at: Time.now(),
      site_id: site.id,
      ip: request.ip,
      user_agent: request.user_agent,
      properties: Sequel.pg_json(params),
    }
  end

  def write_log
    @log[:finished_at] = Time.now()
    DB[:log].insert(@log)
  end

  def require_auth
    return unless settings.production?
    token = request.env['HTTP_AUTHORIZATION'] || params['access_token'] || ""
    token.sub!(/^Bearer /,'')
    if token.empty?
      raise Auth::NoTokenError.new
    end
    scope = params.key?('action') ? params['action'] : 'post'
    Auth.verify_token_and_scope(token, scope)
    # TODO: check "me" for domain match
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
  #
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

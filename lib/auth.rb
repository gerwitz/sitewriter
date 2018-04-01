module Auth
  module_function

  def url_via_indieauth(our_url, code)
    # TODO: use our own endpoint instead of IndieAuth.com
    response = HTTParty.post('https://indieauth.com/auth', {
      body: {
        code: code,
        client_id: "#{our_url}",
        redirect_uri: "#{our_url}login"
      },
      headers: { 'Accept' => 'application/json' }
    })
    unless response.code.to_i == 200
      if result = JSON.parse(response.body)
        raise SitewriterError.new(result.error, result.error_description, response.code.to_i)
      else
        raise SitewriterError.new("indieauth", "Unrecognized IndieAuth error", 500)
      end
    end
    body = JSON.parse(response.body)
    if body['me']
      return body['me']
    else
      raise SitewriterError.new("indieauth", "Invalid IndieAuth response", 500)
    end
  end

  # TODO: don't assume we know the token endpoint!
  def verify_token_and_scope(token, scope)
    response = get_token_response(token, ENV['TOKEN_ENDPOINT'])
    unless response.code.to_i == 200
      raise ForbiddenError.new
    end

    response_hash = CGI.parse(response.parsed_response)
    if response_hash.key?('scope') && response_hash['scope'].is_a?(Array)
      scopes = response_hash['scope'][0].split(' ')
      return if scopes.include?(scope)
      # if we want to post and are allowed to create then go ahead
      return if scope == 'post' && scopes.include?('create')
    end
    raise InsufficientScope.new
  end

  def get_token_response(token, token_endpoint)
    HTTParty.get(
      token_endpoint,
      headers: {
        'Accept' => 'application/x-www-form-urlencoded',
        'Authorization' => "Bearer #{token}"
      })
  end

  def verify_github_signature(body, header_signature)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'),
      ENV['GITHUB_SECRET'], body)
    unless Rack::Utils.secure_compare(signature, header_signature)
      raise ForbiddenError.new("GitHub webhook signatures did not match.")
    end
  end

  class NoTokenError < SitewriterError
    def initialize(message="Micropub endpoint did not return an access token.")
      super("unauthorized", message, 401)
    end
  end

  class InsufficientScope < SitewriterError
    def initialize(message="The user does not have sufficient scope to perform this action.")
      super("insufficient_scope", message, 401)
    end
  end

  class ForbiddenError < SitewriterError
    def initialize(message="The authenticated user does not have permission" +
        " to perform this request.")
      super("forbidden", message, 403)
    end
  end

end

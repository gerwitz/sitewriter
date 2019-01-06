# module Transformative
class Github < Store

  def type_desc
    return "GitHub"
  end

  def name
    return "GitHub (#{github_full_repo})"
  end

  def put(filename, content, description="post")
    puts "put: filename=#{filename}"
    # content = JSON.pretty_generate(data)
    if existing = get_file(filename)
      unless Base64.decode64(existing['content']) == content
        update(existing['sha'], filename, content, description)
      end
    else
      create(filename, content, description)
    end
  end

  def create(filename, content, description)
    octokit.create_contents(
      github_full_repo,
      filename,
      "New #{description} (via sitewriter.net)",
      content
    )
  end

  def update(sha, filename, content, description)
    octokit.update_contents(
      github_full_repo,
      filename,
      "Updated #{description} (via sitewriter.net)",
      sha,
      content
    )
  end

  def upload(filename, file, description="file")
    octokit.create_contents(
      github_full_repo,
      filename,
      "New #{description} (via sitewriter.net)",
      {file: file}
    )
  end

  # broken
  def get(filename)
    file_content = get_file_content(filename)
    data = JSON.parse(file_content)
    url = filename.sub(/\.json$/, '')
    klass = Post.class_from_type(data['type'][0])
    klass.new(data['properties'], url)
  end

  def get_url(url)
    relative_url = Utils.relative_url(url)
    get("#{relative_url}.json")
  end

  def exists_url?(url)
    relative_url = Utils.relative_url(url)
    get_file("#{relative_url}.json") != nil
  end

  def get_file(filename)
    begin
      octokit.contents(github_full_repo, { path: filename })
    rescue Octokit::NotFound
    end
  end

  def get_file_content(filename)
    base64_content = octokit.contents(
      github_full_repo,
      { path: filename }
    ).content
    Base64.decode64(base64_content)
  end

  # def webhook(commits)
  #   commits.each do |commit|
  #     process_files(commit['added']) if commit['added'].any?
  #     process_files(commit['modified'], true) if commit['modified'].any?
  #   end
  # end
  #
  # def process_files(files, modified=false)
  #   files.each do |file|
  #     file_content = get_file_content(file)
  #     url = "/" + file.sub(/\.json$/,'')
  #     data = JSON.parse(file_content)
  #     klass = Post.class_from_type(data['type'][0])
  #     post = klass.new(data['properties'], url)
  #
  #     if %w( h-entry h-event ).include?(data['type'][0])
  #       if modified
  #         existing_webmention_client =
  #           ::Webmention::Client.new(post.absolute_url)
  #         begin
  #           existing_webmention_client.crawl
  #         rescue OpenURI::HTTPError
  #         end
  #         Cache.put(post)
  #         existing_webmention_client.send_mentions
  #       else
  #         Cache.put(post)
  #       end
  #       ::Webmention::Client.new(post.absolute_url).send_mentions
  #       Utils.ping_pubsubhubbub
  #       Context.fetch_contexts(post)
  #     else
  #       Cache.put(post)
  #     end
  #   end
  # end

  def github_full_repo
    "#{user}/#{location}"
  end

  def octokit
    @octokit ||= Octokit::Client.new(access_token: key)
    # @octokit ||= case (ENV['RACK_ENV'] || 'development').to_sym
    #   when :production
    #     Octokit::Client.new(access_token: key)
    #   else
    #     FileSystem.new
    #   end
  end

end
# end

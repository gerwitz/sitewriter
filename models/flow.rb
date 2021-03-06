class Flow < Sequel::Model

  require 'mustermann'

  many_to_one :site
  many_to_one :store
  many_to_one :media_store, class: :Store

  def name
    if post_kind
      return post_kind.capitalize
    else
      return "Files"
    end
  end

  def url_pattern
    return Mustermann.new(url_template) # type: :sinatra
  end
  def path_pattern
    return Mustermann.new(path_template) # type: :sinatra
  end
  def media_url_pattern
    return Mustermann.new(media_url_template) # type: :sinatra
  end
  def media_path_pattern
    return Mustermann.new(media_path_template) # type: :sinatra
  end

  def url_for_post(post)
    begin
      relative_url = url_pattern.expand(:ignore, post.render_variables)
      return URI.join(site.url, relative_url).to_s
    rescue => e
      puts "#{e.message} #{e.backtrace.join("\n")}"
      raise SitewriterError.new("template", "Unable to generate post url: #{e.message}", 500)
    end
  end

  def file_path_for_post(post)
    begin
      return path_pattern.expand(:ignore, post.render_variables)
    rescue => e
      puts "#{e.message} #{e.backtrace.join("\n")}"
      raise SitewriterError.new("template", "Unable to generate file path: #{e.message}", 500)
    end
  end

  def file_content_for_post(post)
    begin
      return Mustache.render(content_template, post.render_variables).encode(universal_newline: true)
    rescue => e
      puts "#{e.message} #{e.backtrace.join("\n")}"
      raise SitewriterError.new("template", "Unable to apply content template: #{e.message}", 500)
    end
  end

  def store_post(post)
    store.put(file_path_for_post(post), file_content_for_post(post), post_kind)
    return url_for_post(post)
  end

  def url_for_media(media)
    relative_url = media_url_pattern.expand(:ignore, media.render_variables)
    return URI.join(site.url, relative_url).to_s
  end

  def file_path_for_media(media)
    return media_path_pattern.expand(:ignore, media.render_variables)
  end

  def store_file(media)
    media_store.upload(file_path_for_media(media), media.file, "file")
    return url_for_media(media)
  end

  def attach_photo_url(post, url)
    # TODO: allow alt text in hash for JSON (spec 3.3.2)
    post.attach_url(:photo, url)
  end

  def attach_photo_media(post, media)
    file_flow = site.file_flow
    url = file_flow.store_file(media)
    post.attach_url(:photo, url)
  end

end

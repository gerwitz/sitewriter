class Flow < Sequel::Model

  require 'mustache'

  # def handles_type?(type)
  #   return post_types.contains(type)
  # end
  many_to_one :site
  many_to_one :store
  many_to_one :media_store, class: :Store

  def post_type
    return Post::TYPES[post_type_id].to_s
  end

  def url_for_post(post)
    relative_url = Mustache.render(url_template, post.view_properties)
    return URI.join(site.url, relative_url).to_s
  end

  def file_path_for_post(post)
    Mustache.render(path_template, post.view_properties)
  end

  def file_content_for_post(post)
puts "🐌 post.view_properties: #{post.view_properties.inspect}"
puts "🐌 as json: #{post.view_properties.to_json}"

    Mustache.render(content_template, post.view_properties)
  end

  def store_post(post)
    store.put(file_path_for_post(post), file_content_for_post(post))
    return url_for_post(post)
  end

  def url_for_media(media)
    relative_url = Mustache.render(media_url_template, media.view_properties)
    return URI.join(site.url, relative_url).to_s
  end

  def file_path_for_media(media)
    Mustache.render(media_path_template, media.view_properties)
  end

  def store_file(media)
    media_store.upload(file_path_for_media(media), media.file)
    return url_for_media(media)
  end

  def attach_photos(post, photos)
    if photos.is_a?(Array)
      photos.map do |item|
        if item.is_a?(Array)
          attach_photos(post, item)
        else
          attach_photo(post, item)
        end
      end
    else
      attach_photo(post, photos)
    end
  end

  def attach_photo(post, photo)
    # TODO: allow alt text in hash for JSON (spec 3.3.2)
    if self.class.valid_url?(photo)
      post.attach_url(:photo, photo)
    else
      url = store_file(photo)
      post.attach_url(:photo, url)
    end
  end

  def self.valid_url?(url)
    begin
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError
    end
  end

end

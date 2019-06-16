class Media
  require 'rack/mime'

  def initialize(file_hash)
    @file = file_hash[:tempfile]
    @time = Time.now.utc.to_datetime

    type = file_hash[:type]
    if filename = file_hash[:filename]
      extension = File.extname(filename)[1..-1]
      @slug = "#{@time.strftime('%H%M%S')}-#{File.basename(filename, extension)}_#{SecureRandom.hex(2).to_s}"
    else
      @slug = "#{@time.strftime('%H%M%S')}-#{SecureRandom.hex(8).to_s}"
    end
    @extension = extension || Rack::Mime::MIME_TYPES.invert[type][1..-1]
  end

  def post_slug=(post_slug)
    @post_slug = post_slug
  end

  def render_variables
    vars = {
      slug: @slug,
      extension: @extension,
      date: @time.strftime('%Y-%m-%d'),
      year: @time.strftime('%Y'),
      month: @time.strftime('%m'),
      day: @time.strftime('%d'),
      hour: @time.strftime('%H'),
      minute: @time.strftime('%M'),
      second: @time.strftime('%S'),
      year_month: @time.strftime('%Y-%m')
    }

    if @post_slug
      vars.merge!({
        post_slug: @post_slug
      })
    end

    return vars
  end

  def file
    @file
  end

  def self.variables(is_attachment=false)
    vars = {
      slug: 'slug (filename)',
      extension: 'file extension',

      date: 'upload date (YYYY-MM-DD)',
      year: 'upload year (YYYY)',
      month: 'upload month (01-12)',
      day: 'day of upload month (01-31)',
      hour: 'hour of upload (00-23)',
      minute: 'minute of upload',
      second: 'second of upload',
      year_month: 'year and month (YYYY-MM)'
    }

    if is_attachment
      vars.merge!({
        post_slug: 'the post slug'
      })
    end

    return vars
  end

end

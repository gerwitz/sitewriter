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

  def render_variables
    {
      slug: @slug,
      extension: @extension,
      year: @time.strftime('%Y'),
      month: @time.strftime('%m'),
      day: @time.strftime('%d'),
      hour: @time.strftime('%H'),
      minute: @time.strftime('%M'),
      second: @time.strftime('%S'),
      year_month: @time.strftime('%Y-%m')
    }
  end

  def file
    @file
  end
end

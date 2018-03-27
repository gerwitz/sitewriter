class Media
  require 'rack/mime'

  def initialize(file_hash)
    @file = file_hash[:tempfile]
    @time = Time.now.utc.to_datetime

    type = file_hash[:type]
    if filename = file_hash[:filename]
      extension = File.extname(filename)
      @slug = "#{@time.strftime('%H%M%S')}-#{File.basename(filename, extension)}_#{SecureRandom.hex(2).to_s}"
    else
      @slug = "#{@time.strftime('%H%M%S')}-#{SecureRandom.hex(8).to_s}"
    end
    @extension = extension || Rack::Mime::MIME_TYPES.invert[type]
  end

  def view_properties
    {
      slug: @slug,
      extension: @extension,
      date_time: @time.rfc3339,
      year: @time.strftime('%Y'),
      month: @time.strftime('%m'),
      day: @time.strftime('%d')
    }
  end

  def file
    @file
  end
end

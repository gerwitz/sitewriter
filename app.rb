require 'sinatra'

class SiteWriter < Sinatra::Application
  # enable :sessions

  configure :production do
    set :haml, { :ugly=>true }
    set :clean_trace, true
    set :show_exceptions, false # supposed to be the default?
  end

  configure :development do
    # ...
  end

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
  end
end

class SitewriterError < StandardError
  attr_reader :type, :status
  def initialize(type, message, status=500)
    @type = type
    @status = status.to_i
    super(message)
  end
end

require_relative 'lib/init'
require_relative 'models/init'
# require_relative 'helpers/init'
require_relative 'routes/init'

configure do
  # use Rack::SSL if settings.production?

  # this feels like an odd hack to avoid Sinatra's natural directory structure
  root_path = "#{File.dirname(__FILE__)}/../"
  set :config_path, "#{root_path}config/"
  set :syndication_targets, {}
  set :markdown, layout_engine: :erb
  set :server, :puma

  set :views, "#{root_path}views/"
end

before do
  headers \
    "Referrer-Policy" => "no-referrer",
    "Content-Security-Policy" => "script-src 'self'"
end

require_relative 'manage'
require_relative 'micropub'
require_relative 'webmention'

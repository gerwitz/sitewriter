$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

env = ENV['RACK_ENV'].to_sym

require "bundler/setup"
Bundler.require(:default, env)

Dotenv.load unless env == :production

# optionally use sentry in production
if env == :production && ENV.key?('SENTRY_DSN')
  Raven.configure do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.processors -= [Raven::Processor::PostData]
  end
  use Raven::Rack
end

# automatically parse json in the body
use Rack::PostBodyContentTypeParser

# session pool using redis via moneta
require 'rack/session/moneta'
use Rack::Session::Moneta,
    key:            'sitewriter.net',
    path:           '/',
    expire_after:   7*24*60*60, # one week
    secret:         ENV['SESSION_SECRET_KEY'],

    store:          Moneta.new(:Redis, {
        url:            ENV['REDISCLOUD_URL'],
        expires:        true,
        threadsafe:     true
    })

root = ::File.dirname(__FILE__)
require ::File.join( root, 'app' )
run SiteWriter.new

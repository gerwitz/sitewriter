class SiteWriter < Sinatra::Application
  get '/' do
    erb :index
  end

  get '/tools' do
    erb :tools
  end
end

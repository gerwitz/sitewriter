class SiteWriter < Sinatra::Application

  get '/:domain/webmention' do
    "Webmention endpoint"
  end

  post '/:domain/webmention' do
    puts "Webmention params=#{params}"
    Webmention.receive(params[:source], params[:target])
    headers 'Location' => params[:target]
    status 202
  end

end

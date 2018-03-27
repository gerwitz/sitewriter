class SiteWriter < Sinatra::Application
  helpers Sinatra::LinkHeader
  # helpers ViewHelper

  enable :sessions

  get '/' do
    @sites = Site.all
    erb :index
  end

  get '/login' do
    if params.key?('code') # this is probably an indieauth callback
      url = Auth.url_via_indieauth("#{request.scheme}://#{request.host_with_port}/", params[:code])
      login_url(url)
    end
    if session[:domain]
      redirect "/#{session[:domain]}/"
    else
      redirect '/'
    end
  end

  get '/logout' do
    session.clear
    redirect '/'
  end

  get '/:domain' do
    redirect "/#{params[:domain]}/"
  end

  get '/:domain/' do
    auth_for_domain
    @site = find_site
    erb :site
  end

  post '/:domain/stores' do
    auth_for_domain
    @site = find_site
    if params.key?('type_id')
      type_id = params['type_id'].to_i
      store_class = Store.sti_class_from_sti_key(type_id)
      # puts "type: #{type_id}, class: #{store_class}"
      store = store_class.create(site_id: @site.id)
      store.update_fields(params, [:location, :user, :key])
    else
      raise TransformativeError.new("bad_request", "Can't POST a store without a type")
    end
    redirect "/#{@site.domain}/"
  end

  post '/:domain/flows' do
    auth_for_domain
    # auth_for_domain(params[:domain])
    @site = find_site
    if params.key?('id')
      # editing
      flow = Flow.first(id: params[:id].to_i)
      flow.update_fields(params, [
        :store_id,
        :name,
        :path_template,
        :url_template,
        :content_template,
        :allow_media,
        :media_store_id,
        :media_path_template,
        :media_url_template,
        :allow_meta
      ])
      redirect "/#{@site.domain}/"
    else
      # creating
      flow = Flow.find_or_create(site_id: @site.id, post_type_id: params[:post_type_id].to_i)
      # flow.update_fields(params, [:post_type_id])
      redirect "/#{@site.domain}/flows/#{flow.id}"
    end
  end

  get '/:domain/flows/:id' do
    auth_for_domain
    @site = find_site
    @flow = Flow.find(id: params[:id].to_i, site_id: @site.id)
    erb :flow
  end

  not_found do
    status 404
    erb :'404'
  end

  error TransformativeError do
    e = env['sinatra.error']
    json = {
      error: e.type,
      error_description: e.message
    }.to_json
    halt(e.status, { 'Content-Type' => 'application/json' }, json)
  end

  error do
    erb :'500', layout: false
  end

  def deleted
    status 410
    erb :'410'
  end

private

  # login with domain from url
  def login_url(url)
    domain = URI.parse(url).host.downcase
    @site = Site.find_or_create(domain: domain)
    @site.url = url
    @site.save
    session[:domain] = domain
  end

  def find_site
    if params[:domain]
      site = Site.first(domain: params[:domain].to_s)
      if site.nil?
        raise StandardError.new("No site found for '#{params[:domain].to_s}'")
      else
        return site
      end
    else
      not_found
    end
  end

  def auth_for_domain(domain = nil)
    return if ENV['RACK_ENV'].to_sym == :development
    domain ||= params[:domain]
    if domain != session[:domain]
      redirect '/'
    end
  end

end

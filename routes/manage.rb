class SiteWriter < Sinatra::Application
  helpers Sinatra::LinkHeader
  # helpers ViewHelper

  enable :sessions

  get '/login' do
    if params.key?('code') # this is probably an indieauth callback
      url = Auth.url_via_indieauth("#{request.scheme}://#{request.host_with_port}/", params[:code])
      login_url(url)
    end
    if session[:domain]
      redirect "/#{session[:domain]}/"
    else
      # it didn't work
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
    @site = auth_site
    erb :site_overview
  end

  get '/:domain/config' do
    @site = auth_site
    site_flows = @site.flows_dataset
    @flows = Post::TYPES.map do |kind|
      flow = site_flows.where(post_kind: kind.to_s).exclude(store_id: nil).first
      if flow
        {
          kind: kind,
          flow: flow
        }
      else
        { kind: kind }
      end
    end
    erb :site_config
  end

  get '/:domain/stores/new' do
    @site = auth_site
    erb :store_new
  end

  post '/:domain/stores' do
    @site = auth_site
    if params.key?('type_id')
      type_id = params['type_id'].to_i
      store_class = Store.sti_class_from_sti_key(type_id)
      # puts "type: #{type_id}, class: #{store_class}"
      store = store_class.create(site_id: @site.id)
      store.update_fields(params, [:location, :user, :key])
      if params.key?('flow_id')
        flow_id = params['flow_id'].to_i
        flow = Flow.where(id: flow_id).first
        flow.store = store
      end
    else
      raise SitewriterError.new("bad_request", "Can't POST a store without a type")
    end
    redirect "/#{@site.domain}/config"
  end

  post '/:domain/flows' do
    @site = auth_site
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
    redirect "/#{@site.domain}/config"
  end

  get '/:domain/flows/new' do
    @site = auth_site
    @flow = Flow.find_or_create(site_id: @site.id, post_kind: params['post_kind'].to_s)
    if @flow.store.nil?
      @flow.update(store_id: @site.default_store.id)
    end
    # flow.update_fields(params, [:post_kind])
    redirect "/#{@site.domain}/flows/#{@flow.id}"
  end

  get '/:domain/flows/:id' do
    @site = auth_site
    @flow = Flow.find(id: params[:id].to_i, site_id: @site.id)
    erb :flow_edit
  end

  get '/:domain/flows/:id/delete' do
    @site = auth_site
    @flow = Flow.find(id: params[:id].to_i, site_id: @site.id)
    @flow.destroy
    redirect "/#{@site.domain}/config"
  end

  not_found do
    status 404
    erb :'404'
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

  def find_site(domain = nil)
    domain ||= params[:domain]
    if domain
      site = Site.first(domain: domain.to_s)
      if site.nil?
        raise SitewriterError.new("bad_request", "No site found for '#{domain}'")
      else
        return site
      end
    else
      not_found
    end
  end

  def auth_site(domain = nil)
    # return if ENV['RACK_ENV'].to_sym == :development
    domain ||= params[:domain]
    if domain == session[:domain]
      return find_site(domain)
    else
      login_site(domain)
    end
  end

  def login_site(domain = nil)
    auth_host = "indieauth.com"
    auth_path = "/auth"

    domain ||= params[:domain]
    auth_query = URI.encode_www_form(
      client_id: "#{request.scheme}://#{ request.host_with_port }/",
      redirect_uri: "#{request.scheme}://#{ request.host_with_port }/login",
      me: domain
    )
    redirect URI::HTTPS.build(
      host: auth_host,
      path: auth_path,
      query: auth_query
    ), 302
  end
  #
  #   def auth_domain
  #
  #   if params[:domain]
  #     site = Site.first(domain: params[:domain].to_s)
  #
  #
  #
  #   if params[:domain]
  #     site = Site.first(domain: params[:domain].to_s)
  #     if site.nil?
  #       raise StandardError.new("No site found for '#{params[:domain].to_s}'")
  #     else
  #       return site
  #     end
  #   else
  #     not_found
  #   end
  # end
  #
  # def auth_for_domain(domain = nil)
  #   return if ENV['RACK_ENV'].to_sym == :development
  #   domain ||= params[:domain]
  #   if domain != session[:domain]
  #     redirect '/'
  #   end
  # end

end

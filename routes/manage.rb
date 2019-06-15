class SiteWriter < Sinatra::Application
  helpers Sinatra::LinkHeader

  enable :sessions

  get '/syslog/?' do
    env = ENV['RACK_ENV'].to_sym || :development
    halt(404) unless (session[:domain] == 'hans.gerwitz.com') || (env == :development)
    @log = DB[:log].reverse_order(:started_at)
    erb :syslog
  end

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
    erb :site_status
  end

  post '/:domain/settings?' do
    @site = auth_site
    # puts "☣️ Updating #{@site.domain}"
    @site.update_fields(params, [
      :timezone
    ])
    # puts("updated timezone to #{@site.timezone}")
    redirect "/#{@site.domain}/settings"
  end

  get '/:domain/posting' do
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
    erb :site_posting
  end

  get '/:domain/stores/new' do
    @site = auth_site
    if params.key?('type_id')
      type_id = params['type_id'].to_i
    else
      type_id = 1 # github
    end
    store_class = Store.sti_class_from_sti_key(type_id)
    @store = store_class.create(site_id: @site.id)
    erb :store_edit
  end

  get '/:domain/stores/:id' do
    @site = auth_site
    @store = Store.find(id: params[:id].to_i, site_id: @site.id)
    erb :store_edit
  end

  post '/:domain/stores' do
    @site = auth_site

    store = Store.first(id: params[:id].to_i, site_id: @site.id)

    # if params.key?('type_id')
    #   type_id = params['type_id'].to_i
    #   store_class = Store.sti_class_from_sti_key(type_id)
    #   # puts "type: #{type_id}, class: #{store_class}"
    #   store = store_class.create(site_id: @site.id)
      store.update_fields(params, [
        :location,
        :user,
        :key
      ])
      if params.key?('flow_id')
        flow_id = params['flow_id'].to_i
        flow = Flow.first(id: flow_id)
        flow.store = store
        flow.save
      end
    # else
    #   raise SitewriterError.new("bad_request", "Can't POST a store without a type")
    # end
    redirect "/#{@site.domain}/posting"
  end

  get '/:domain/stores/:id/delete' do
    @site = auth_site
    @store = Store.find(id: params[:id].to_i, site_id: @site.id)
    @store.destroy
    redirect "/#{@site.domain}/posting"
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

  get '/:domain/flows/media' do
    @site = auth_site
    @flow = @site.file_flow
    if @flow.nil?
      @flow = Flow.create(site_id: @site.id, allow_media: true, media_store_id: @site.default_store.id)
      @site.update(file_flow_id: @flow.id)
      puts "☣️ Created new file flow [#{@flow.id}] for #{@site.domain}"
    end
    # if @flow.media_store.nil?
    #   @flow.update(media_store_id: @site.default_store.id)
    # end
    erb :flow_media
  end

  post '/:domain/flows/media' do
    @site = auth_site
    flow = @site.file_flow
    puts "☣️ Updating file flow #{flow.id}"
    flow.update(post_kind: nil)
    flow.update_fields(params, [
      :media_path_template,
      :media_url_template
    ])
    redirect "/#{@site.domain}/uploading"
  end


  get '/:domain/flows/:id' do
    @site = auth_site
    @flow = Flow.first(id: params[:id].to_i, site_id: @site.id)
    erb :flow_edit
  end

  post '/:domain/flows' do
    @site = auth_site
    flow = Flow.first(id: params[:id].to_i, site_id: @site.id)
    flow.update_fields(params, [
      # :name,
      :path_template,
      :url_template,
      :content_template,
      :allow_media,
      :media_store_id,
      :media_path_template,
      :media_url_template
      # :allow_meta
    ])
    redirect "/#{@site.domain}/posting"
  end

  get '/:domain/flows/:id/delete' do
    @site = auth_site
    @flow = Flow.find(id: params[:id].to_i, site_id: @site.id)
    @flow.destroy
    redirect "/#{@site.domain}/posting"
  end

  not_found do
    status 404
    erb :'404'
  end

  error do
    status 500
    erb :'500', layout: false
  end

private

  # login with domain from url
  def login_url(url)
    domain = URI.parse(url).host.downcase
    @site = Site.find_or_create(domain: domain)
    @site.url = url
    @site.save
    session[:domain] = domain
    if domain == 'hans.gerwitz.com'
      session[:admin] = true
    else
      session[:admin] = false
    end
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
    env = ENV['RACK_ENV'] || 'development'
    if (domain == session[:domain]) || session[:admin] || (env.to_sym == :development)
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

end

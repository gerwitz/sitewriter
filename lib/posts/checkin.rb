class Checkin < Post

  VARIABLES_CATALOG = {
    name: 'name of venue',
    url: 'venue URL',

    latitude: 'venue latitude',
    longitude: 'venue longitude',

    address: 'venue street address',
    locality: 'venue city',
    region: 'venue region',
    country: 'venue country',
    postal: 'venue postal code',

    tel: 'venue telephone number'
  }

  def initialize(properties, url=nil)
    super(properties, url)
    @name = ''
    @url = ''
    @latitude = ''
    @longitude = ''
    @address = ''
    @locality = ''
    @region = ''
    @country = ''
    @postal = ''
    @telephone = ''
    if properties.key?('checkin')
      checkin_props = properties['checkin'][0]
      if checkin_props.key?('name')
        @name = checkin_props['name'][0]
      else
        @name = ''
      end
      if checkin_props.key?('url')
        @url = checkin_props['url'][0]
      else
        @url = ''
      end
      if checkin_props.key?('latitude')
        @latitude = checkin_props['latitude'][0]
      else
        @latitude = ''
      end
      if checkin_props.key?('longitude')
        @longitude = checkin_props['longitude'][0]
      else
        @longitude = ''
      end
      if checkin_props.key?('street-address')
        @address = checkin_props['street-address'][0]
      else
        @address = ''
      end
      if checkin_props.key?('locality')
        @locality = checkin_props['locality'][0]
      else
        @locality = ''
      end
      if checkin_props.key?('region')
        @region = checkin_props['region'][0]
      else
        @region = ''
      end
      if checkin_props.key?('country')
        @country = checkin_props['country'][0]
      else
        @country = ''
      end
      if checkin_props.key?('postal-code')
        @postal = checkin_props['postal-code'][0]
      else
        @postal = ''
      end
      if checkin_props.key?('tel')
        @telephone = checkin_props['tel'][0]
      else
        @telephone = ''
      end
      # default slug
      @slug = @name || @locality || @region || @country
    end
  end

  def kind
    'checkin'
  end

  def render_variables
    return super().merge({
      name: @name,
      url: @url,

      latitude: @latitude,
      longitude: @longitude,

      address: @address,
      locality: @locality,
      region: @region,
      country: @country,
      postal: @postal,

      telephone: @telephone
    })
  end

end

# encoding: UTF-8 (magic comment)

class CTT2013::Application < Sinatra::Base

  # Set locale
  before '/:loc/*' do |loc, path|
    if locale = LOCALE_FROM_URL_LOCALE_FRAGMENT["#{ loc }/"]
      set_locale(locale)
      request.path_info = "/#{ path }"
    end
  end

  # Cache control
  before '/*' do |path|
    if path =~ %r{\Aorg/}
      cache_control :no_cache
    else
      cache_control :public, :must_revalidate, :max_age => 60
    end
  end

  # This is needed to close connections at the end of each request when
  # the applicaiton is run from the command line with "Thin" web server.
  # It seems that with "Apache" it is enough to unclude the middleware
  # configuration
  #
  #   use ActiveRecord::ConnectionAdapters::ConnectionManagement
  #
  # in an appropriate place.
  after do
    ActiveRecord::Base.connection.close
  end
end

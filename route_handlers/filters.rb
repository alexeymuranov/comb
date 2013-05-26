# encoding: UTF-8 (magic comment)

class CTT2013 < Sinatra::Base

  # Cache control
  before do
    cache_control :public, :must_revalidate, :max_age => 60
  end

  before %r{/org/} do
    cache_control :no_cache
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

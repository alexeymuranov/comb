require 'sinatra/base'

require_relative 'init'

# Host-specific constant (for IMT web site)
CTT2013::BASE_URL = Sinatra::Base.production? ? '/top-geom-conf-2013/' : '/'

# encoding: UTF-8 (magic comment)

require 'sinatra/base'

require 'sinatra/flash' # Session-based flash

require 'i18n' # Internationalisation

require 'active_record'

class CTT2013 < Sinatra::Base

  if development?
    require 'debugger'      # Ruby debugger
    require 'better_errors' # better error pages
  end

  # Settings
  # ========

  # Host-specific constants (for IMT web site)
  BASE_URL = production? ? '/top-geom-conf-2013/' : '/'

  configure do
    set :app_file        => __FILE__,
        :root            => File.dirname(__FILE__),
        :views           => File.join(settings.root, 'view_templates'),
        :public_folder   => File.join(settings.root, 'public_folder'),
        :method_override => true # enable the POST _method hack

    # Enable/disable cookie based sessions
    # enable for flash messages in registration form and authentication
    set :sessions, :path => BASE_URL

    # set :bind, 'localhost' # server hostname or IP address
    # set :port, 4567        # server port
    # set :lock, true        # ensure single request concurrency with a mutex lock
  end

  # This seems to be needed to automatically close connections at the end of
  # each request.  Not sure if and how this works.  This does not work when
  # the applicaiton is run from the command line with "Thin" web server.
  # For that case, connections need to be closed explicitely in an "after"
  # filter.
  use ActiveRecord::ConnectionAdapters::ConnectionManagement

  configure :development do
    use BetterErrors::Middleware
    BetterErrors.application_root = File.expand_path('..', __FILE__)
  end

  configure :production do
    # Do not "pretty print" HTML for better performance
    set :haml, { :ugly => true }
  end

  # Internationalisation
  # --------------------

  LOCALES = [:en, :fr]
  DEFAULT_LOCALE = :fr

  configure do
    I18n.load_path =
      Dir[::File.join(settings.root, 'internationalisation/**/*.{rb,yml}')]
    I18n.default_locale = DEFAULT_LOCALE
  end

  # Sessions
  # --------

  # Session-based flash
  register Sinatra::Flash
end

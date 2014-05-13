# encoding: UTF-8 (magic comment)

Encoding.default_external = Encoding::UTF_8
# Encoding.default_internal = Encoding::UTF_8

require 'set' # to use Set data structure

require 'digest' # to hash passwords

require 'yaml'

require 'cgi' # "Common Gateway Interface", HTTP tools (escape query string, for example)

require 'csv' # to generate CSV files for download

require 'haml'
require 'sass'
require 'redcarpet' # Markdown

# XXX: Because of some bug, 'active_record' needs to be required before 'pony'.
require 'active_record'
require 'pony' # Email

require 'reverse_markdown' # HTML to markdown for text email body

require 'sinatra/base'

if Sinatra::Base.development?
  require 'debugger'      # Ruby debugger
  require 'better_errors' # better error pages
end

require 'sinatra/flash' # Session-based flash

require 'i18n' # Internationalisation

require 'active_record'

class CTT2013 < Sinatra::Base
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

    # Unfortunately this does not work:
    # set :markdown, :tables => true
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

require_relative 'lib/for_sass'

require_relative 'lib/simple_relation_filter'

require_relative 'models/init'

require_relative 'helpers/init'

require_relative 'route_handlers/init'

if __FILE__ == $0
  CTT2013.run!
end

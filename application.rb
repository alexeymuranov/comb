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

require_relative 'init'

module CTT2013
  require_relative 'base_url'

  # For internationalisation
  LOCALES = [:en, :fr]
  DEFAULT_LOCALE = :fr

  # Create Sinatra web application
  Application = Class.new(Sinatra::Base)

  require_relative 'lib/for_sass'

  require_relative 'lib/simple_relation_filter'

  require_relative 'models/all'

  require_relative 'helpers/all'

  require_relative 'route_handlers/all'

  # Settings
  # ========
  Application.instance_eval do
    configure do
      set :app_file, __FILE__
      set :root, File.dirname(settings.app_file)
      set :views         => File.join(settings.root, 'view_templates'),
          :public_folder => File.join(settings.root, 'public_folder')
      enable :method_override  # enable "_method" hack for POST requests

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
      BetterErrors.application_root = settings.root
    end

    configure :production do
      # Do not "pretty print" HTML for better performance
      set :haml, { :ugly => true }
    end

    # Internationalisation
    # --------------------

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
end

CTT2013::Application.run! if __FILE__ == $0

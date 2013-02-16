# encoding: UTF-8 (magic comment)

require 'rubygems'

require 'bundler/setup'

require 'sinatra/base'

require 'set' # to use Set data structure

require 'digest' # to hash passwords

require 'yaml'

class CTT2013 < Sinatra::Base

  require 'active_record'
  require 'logger'
  require 'sqlite3'

  require 'haml'
  require 'sass'
  require 'redcarpet' # Markdown

  require 'pony' # Email

  require 'i18n' # Internationalisation

  require 'sinatra/flash' # Session-based flash

  require 'reverse_markdown' # HTML to markdown for text email body

  if development?
    require 'debugger'      # Ruby debugger
    require 'better_errors' # better error pages
  end

  # Settings
  # ========

  # Host-specific constants
  if production?
    # For IMT web site
    BASE_URL = '/top-geom-conf-2013/'
    REQUEST_BASE_URL = '/'
  else
    # For localhost
    REQUEST_BASE_URL = BASE_URL = '/'
  end

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

  configure :development do
    use BetterErrors::Middleware
    BetterErrors.application_root = File.expand_path('..', __FILE__)
  end

  # Internationalisation
  # --------------------

  LOCALES = [:en, :fr]
  DEFAULT_LOCALE = :fr

  I18n.load_path =
    Dir[::File.join(settings.root, 'internationalisation/**/*.{rb,yml}')]
  I18n.default_locale = DEFAULT_LOCALE

  # Sass
  # ----

  require_relative 'lib/for_sass'

  # Sessions
  # --------

  # Session-based flash
  register Sinatra::Flash

  # ActiveRecord Models
  # ===================
  #

  def self.connect_database(environment = settings.environment)
    ActiveRecord::Base.logger = Logger.new("log/#{ environment }.log")
    ActiveRecord::Base.configurations = YAML::load(IO.read('config/database.yml'))
    ActiveRecord::Base.establish_connection(environment)
  end

  require_relative 'models/models'
  require './lib/simple_relation_filter'

  # Handlers
  # ========
  #

  # Cache control
  before do
    cache_control :public, :must_revalidate, :max_age => 60
  end

  # View helpers
  # ============
  #
  require_relative 'helpers/complex'
  helpers Helpers

  require_relative 'helpers/presentation'
  helpers PresentationHelpers

end

require_relative 'route_handlers/init'

if __FILE__ == $0
  CTT2013.connect_database
  CTT2013.run!
end

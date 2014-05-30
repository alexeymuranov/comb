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

  # Constants and private methods
  class Application

    # Pages
    # -----

    COMMON_HOME_PAGE = 'common/index.php'

    COMB_PAGE_PREFIX = 'ldtg-mb/'

    PUBLIC_PAGES =
      [ 'index',
        'program',
        'scientific_committee',
        'organising_committee',
        'directions_to_get_here',
        'funding',
        'contacts',
        'accommodation',
        'participants',
        'registration', # only displays that registration is closed
        'useful_links'
      ].map{|p| "#{ COMB_PAGE_PREFIX }#{ p }" }

    STATIC_PUBLIC_PAGES =
      Set[ 'index',
           'program',
           'scientific_committee',
           'organising_committee',
           'directions_to_get_here',
           'funding',
           'contacts',
           'registration',
           'useful_links'
         ].map{|p| "#{ COMB_PAGE_PREFIX }#{ p }" }

    COMB_HOME_PAGE = PUBLIC_PAGES[0]
    PAGE_URL_FRAGMENTS = PUBLIC_PAGES.reduce({}){|h, p| h[p] = [p.to_s]; h }
    PAGE_URL_FRAGMENTS[COMB_HOME_PAGE] << COMB_PAGE_PREFIX

    # Model attributes
    # ----------------

    PARTICIPANT_ATTRIBUTE_NAMES_FOR = {}
    PARTICIPANT_ATTRIBUTE_NAMES_FOR[:registration] =
      Set[ :first_name, :last_name, :email,
           :affiliation, :academic_position,
           :country, :city, :post_code, :street_address, :phone,
           :web_site,
           :i_m_t_member, :g_d_r_member,
           :invitation_needed, :visa_needed,
           # :funding_requests,
           :special_requests ]
    PARTICIPANT_ATTRIBUTE_NAMES_FOR[:create] =
      Set[ :first_name, :last_name, :email, :affiliation,
           :academic_position,
           :country, :city, :post_code, :street_address, :phone,
           :web_site,
           :i_m_t_member, :g_d_r_member,
           :invitation_needed, :visa_needed,
           :funding_requests,
           :special_requests ]
    PARTICIPANT_ATTRIBUTE_NAMES_FOR[:update] =
      PARTICIPANT_ATTRIBUTE_NAMES_FOR[:create]

    TALK_ATTRIBUTE_NAMES_FOR = {}
    TALK_ATTRIBUTE_NAMES_FOR[:create] =
      Set[ :type, :participant_id, :title, :abstract,
           :equipment,
           :date, :time, :room_or_auditorium ]
    TALK_ATTRIBUTE_NAMES_FOR[:update] =
      TALK_ATTRIBUTE_NAMES_FOR[:create]

    HOTEL_ATTRIBUTE_NAMES_FOR = {}
    HOTEL_ATTRIBUTE_NAMES_FOR[:create] =
      Set[:name, :address, :phone, :web_site]
    HOTEL_ATTRIBUTE_NAMES_FOR[:update] = HOTEL_ATTRIBUTE_NAMES_FOR[:create]

    PARTICIPANT_ACCOMMODATION_ATTRIBUTE_NAMES_FOR_CREATE =
      Set[ :hotel_id, :arrival_date, :departure_date ]
    PARTICIPANT_ACCOMMODATION_ATTRIBUTE_NAMES_FOR_UPDATE =
      Set[ :arrival_date, :departure_date ]

    # Internationalisation
    # --------------------

    LOCALE_FROM_URL_LOCALE_FRAGMENT = CTT2013::LOCALES.reduce({}) { |h, locale|
      h["#{ locale }/"] = locale
      h
    }
    # XXX: The assignment of the `DEFAULT_LOCALE` to `''` is not
    # completely consistent with the case of explicit locales.
    LOCALE_FROM_URL_LOCALE_FRAGMENT[''] = CTT2013::DEFAULT_LOCALE

    private

    def set_locale(locale)
      I18n.locale = @locale = locale
      @other_locales = CTT2013::LOCALES - [@locale]
    end

    def locale
      @locale || CTT2013::DEFAULT_LOCALE
    end

    def set_page(page)
      @page = page
      @base_title = t('base_co_m_b_page_title')
      @title =
        "#{ @base_title } | #{ t(:title, :scope => page_i18n_scope(@page)) }"
    end

    def page
      @page
    end

    # def locale_from_user_input(suggested_locale)
    #   suggested_locale = suggested_locale.to_s.downcase
    #   CTT2013::LOCALES.find{|l| l.to_s == suggested_locale } || CTT2013::DEFAULT_LOCALE
    # end

    # def page_from_user_input(suggested_page)
    #   suggested_page = suggested_page.to_s.downcase
    #   PUBLIC_PAGES.find{|p| p.to_s == suggested_page } || COMB_HOME_PAGE
    # end
  end

  require_relative 'lib/for_sass'

  require_relative 'lib/simple_relation_filter'

  require_relative 'models/all'

  require_relative 'helpers/all'
  Application.helpers(*Helpers::ALL)

  require_relative 'route_handlers/all'

  # Settings
  # ========
  Application.instance_eval do
    # NOTE: it seems common to put settings inside a block passed to
    #   `configure` method, but apparently it is useless
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

    # This seems to be needed to automatically close connections at the end of
    # each request.  Not sure if and how this works.  This does not work when
    # the applicaiton is run from the command line with "Thin" web server.
    # For that case, connections need to be closed explicitely in an "after"
    # filter.
    use ActiveRecord::ConnectionAdapters::ConnectionManagement

    if development?
      use BetterErrors::Middleware
      BetterErrors.application_root = settings.root
    end

    if production?
      # Do not "pretty print" HTML for better performance
      set :haml, { :ugly => true }
    end

    # Internationalisation
    # --------------------

    I18n.load_path =
      Dir[::File.join(settings.root, 'internationalisation/**/*.{rb,yml}')]
    I18n.default_locale = DEFAULT_LOCALE

    # Sessions
    # --------

    # Session-based flash
    register Sinatra::Flash
  end
end

CTT2013::Application.run! if __FILE__ == $0

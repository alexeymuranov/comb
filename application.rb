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

  require 'debugger' if development? # for debugging

  require 'reverse_markdown' # HTML to markdown for text email body

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
    set :app_file, __FILE__
    set :root, File.dirname(__FILE__)
    set :views, File.join(settings.root, 'view_templates')
    set :public_folder, File.join(settings.root, 'public_folder')

    set :method_override, true # enable the POST _method hack

    # Enable/disable cookie based sessions
    # enable for flash messages in registration form and authentication
    set :sessions, :path => BASE_URL

    # set :bind, 'localhost' # server hostname or IP address
    # set :port, 4567        # server port
    # set :lock, true        # ensure single request concurrency with a mutex lock
  end

  # Authentication
  # --------------

  class User
    attr_reader :username, :role
    attr_writer :password_hash

    def initialize(username, role = nil)
      @username, @role = username, role
      (@@users ||= Set.new) << self
    end

    def set_password(password)
      @password_hash = Digest::SHA2.base64digest(password)
    end

    def accept_password?(password)
      @password_hash == Digest::SHA2.base64digest(password)
    end

    def id
      object_id
    end

    def self.each
      block_given? ? @@users.each { |u| yield(u) } : @@users.each
    end

    def self.find_by_username(username)
      @@users.find { |u| u.username == username }
    end

    def self.find(id)
      @@users.find { |u| u.id == id }
    end
  end

  User.new('comb', 'organiser').password_hash =
    '6nKIQNNx4aVW9R5XQT/okSB6JcH3Sbb3b88Gjz5Nyt0='

  User.new('gestion', 'main_organiser').password_hash =
    'fqTJyyW7Hg2d90NkzmRPOVSb54LlxgeGMDxF6nmNRt8='

  # Internationalisation
  # --------------------

  LOCALES = [:en, :fr]
  DEFAULT_LOCALE = :fr

  I18n.load_path =
    Dir[::File.join(settings.root, 'internationalisation/**/*.{rb,yml}')]
  I18n.default_locale = DEFAULT_LOCALE

  # Sass
  # ----

  # Needed for Bourbon SCSS library to be used correctly by `scss`:
  require ::File.join(settings.views, 'stylesheets/bourbon/lib/bourbon')

  # Custom sass functions
  #
  module ::Sass::Script::Functions
    def banner_url
      ::Sass::Script::String.new(
        "url('#{ BASE_URL }images/bannerToulouse.jpg');"
      )
    end
  end

  # Sessions
  # --------

  # Session-based flash
  register Sinatra::Flash

  # ActiveRecord
  # ------------

  def self.connect_database(environment = settings.environment)
    ActiveRecord::Base.logger = Logger.new("log/#{ environment }.log")
    ActiveRecord::Base.configurations = YAML::load(IO.read('config/database.yml'))
    ActiveRecord::Base.establish_connection(environment)
  end

  # Models
  # ======
  #
  require_relative 'models'

  PARTICIPANT_ATTRIBUTES = {}
  PARTICIPANT_ATTRIBUTES[:registration] =
    [ :first_name, :last_name, :email,
      :affiliation, :academic_position,
      :country, :city, :post_code, :street_address, :phone,
      :i_m_t_member, :g_d_r_member,
      :invitation_needed, :visa_needed,
      # :arrival_date, :departure_date,
      :funding_requests, :special_requests ]
  PARTICIPANT_ATTRIBUTES[:show] = PARTICIPANT_ATTRIBUTES[:index] =
    [ :first_name, :last_name, :email, :affiliation,
      :academic_position,
      :country, :city, :post_code, :street_address, :phone,
      :i_m_t_member, :g_d_r_member,
      :invitation_needed, :visa_needed,
      # :arrival_date, :departure_date,
      :funding_requests, :special_requests,
      :approved, :co_m_b_committee_comments ]

  TALK_ATTRIBUTES = {}
  TALK_ATTRIBUTES[:show] = TALK_ATTRIBUTES[:index] =
    [ :translated_type_name, :speaker_name, :title, :abstract,
      :date, :time, :room_or_auditorium ]

  HOTEL_ATTRIBUTES = {}
  HOTEL_ATTRIBUTES[:show] = HOTEL_ATTRIBUTES[:index] =
    [:name, :address, :phone, :web_site]

  # Handlers
  # ========
  #

  COMMON_HOME_PAGE = :'common/index.php'

  COMB_PAGE_PREFIX = :'ldtg-mb/'
  ORG_PAGE_PREFIX = :'org/'

  PUBLIC_PAGES = [ :index,
                   :program,
                   :scientific_committee,
                   :organising_committee,
                   :directions_to_get_here,
                   :funding,
                   :contacts,
                   :accommodation,
                   :participants,
                   :registration,
                   :useful_links
                 ].map { |p| :"#{ COMB_PAGE_PREFIX }#{ p }" }

  STATIC_PUBLIC_PAGES = Set[ :index,
                             :program,
                             :scientific_committee,
                             :organising_committee,
                             :directions_to_get_here,
                             :funding,
                             :contacts,
                             :accommodation,
                             :useful_links
                           ].map { |p| :"#{ COMB_PAGE_PREFIX }#{ p }" }

  ORGANISER_CONNEXION_PAGES = [ :participants_to_approve,
                                :participants,
                                :talks,
                                :hotels
                              ].map { |p| :"#{ ORG_PAGE_PREFIX }#{ p }" }

  LOCALE_URL_FRAGMENTS = {}.tap { |h| LOCALES.each { |l| h[l] = ["#{ l }/"] } }
  LOCALE_URL_FRAGMENTS[DEFAULT_LOCALE] << ''

  # LOCALE_URL_FRAGMENT_MAP = { 'fr' => :fr, 'en' => :en, '' => :fr } # this is not used yet

  COMB_HOME_PAGE = PUBLIC_PAGES[0]
  PAGE_URL_FRAGMENTS = {}.tap { |h| PUBLIC_PAGES.each { |p| h[p] = [p.to_s] } }
  PAGE_URL_FRAGMENTS[COMB_HOME_PAGE] << COMB_PAGE_PREFIX

  # Cache control
  before do
    cache_control :public, :must_revalidate, :max_age => 60
  end


  # Handle unmatched requests
  # -------------------------

  not_found do
    send_file ::File.join(settings.public_folder, '404.html')
  end

  # GET requests
  # ------------

  get "#{ REQUEST_BASE_URL }stylesheets/application.css" do
    content_type :css, :charset => 'utf-8'
    scss :'/stylesheets/application.css'
  end


  LOCALES.each do |locale|
    LOCALE_URL_FRAGMENTS[locale].each do |l|
      get "#{ REQUEST_BASE_URL }#{ l }" do
        redirect fixed_url("/#{ COMMON_HOME_PAGE }?lang=#{ locale }")
      end
    end
  end

  LOCALES.each do |locale|
    LOCALE_URL_FRAGMENTS[locale].each do |l|
      get "#{ REQUEST_BASE_URL }#{ l }registration" do
        set_locale(locale)
        @conferences = conferences_from_conference_ids_in_param_array(
                         params[:conference_ids])
        @participant = Participant.new(:conferences => @conferences)
        render_registration_page
      end
    end
  end

  STATIC_PUBLIC_PAGES.each do |page|
    page_file = :"/pages/#{ page }.html"
    LOCALES.each do |locale|
      LOCALE_URL_FRAGMENTS[locale].each do |l|
        PAGE_URL_FRAGMENTS[page].each do |p|
          get "#{ REQUEST_BASE_URL }#{ l }#{ p }" do
            set_locale(locale)
            set_page(page)
            haml page_file, :layout => :layout
          end
        end
      end
    end
  end

  co_m_b_registration_page = :"#{ COMB_PAGE_PREFIX }registration"
  page_file = :"/pages/#{ co_m_b_registration_page }.html"
  LOCALES.each do |locale|
    LOCALE_URL_FRAGMENTS[locale].each do |l|
      PAGE_URL_FRAGMENTS[co_m_b_registration_page].each do |p|
        get "#{ REQUEST_BASE_URL }#{ l }#{ p }" do
          set_locale(locale)
          set_page(co_m_b_registration_page)
          haml page_file, :layout => :layout
        end
      end
    end
  end

  LOCALES.each do |locale|
    LOCALE_URL_FRAGMENTS[locale].each do |l|
      participants_page = :"#{ COMB_PAGE_PREFIX }participants"
      PAGE_URL_FRAGMENTS[participants_page].each do |p|
        # A page that needs access to the database
        get "#{ REQUEST_BASE_URL }#{ l }#{ p }" do
          set_locale(locale)
          set_page(participants_page)

          @participants = Participant.approved.default_order.all

          haml :"/pages/#{ participants_page }.html", :layout => :layout
        end
      end

      get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }login" do
        set_locale(locale)
        set_page(:"#{ ORG_PAGE_PREFIX }login")
        haml :"/pages/#{ ORG_PAGE_PREFIX }login.html"
      end

      get "#{ REQUEST_BASE_URL }#{ l }logout" do
        cache_control :no_cache
        log_out
        redirect fixed_url("/#{ locale }/")
      end

      get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }" do
        require_organiser_login!
        redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }participants_to_approve")
      end

      [ :"#{ ORG_PAGE_PREFIX }participants_to_approve",
        :"#{ ORG_PAGE_PREFIX }participants"
      ].each do |page|
        get "#{ REQUEST_BASE_URL }#{ l }#{ page }" do
          require_organiser_login!
          set_locale(locale)
          set_page(page)
          @attributes = PARTICIPANT_ATTRIBUTES[:index]
          @participants = Participant.scoped
          if page == :"#{ ORG_PAGE_PREFIX }participants_to_approve"
            @participants = @participants.not_all_participations_approved
          end
          @participants = @participants.default_order.all
          haml :"/pages/#{ ORG_PAGE_PREFIX }participants.html"
        end
      end

      get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }talks" do
        require_organiser_login!
        set_locale(locale)
        set_page(:"#{ ORG_PAGE_PREFIX }talks")
        @attributes = TALK_ATTRIBUTES[:index]
        @talks = Talk.default_order.all
        haml :"/pages/#{ ORG_PAGE_PREFIX }talks.html"
      end

      get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }hotels" do
        require_organiser_login!
        set_locale(locale)
        set_page(:"#{ ORG_PAGE_PREFIX }hotels")
        @attributes = HOTEL_ATTRIBUTES[:index]
        @hotels = Hotel.default_order.all
        haml :"/pages/#{ ORG_PAGE_PREFIX }hotels.html"
      end

      [ :"#{ ORG_PAGE_PREFIX }participants_to_approve",
        :"#{ ORG_PAGE_PREFIX }participants"
      ].each do |page|
        get "#{ REQUEST_BASE_URL }#{ l }#{ page }/edit/:id" do |id|
          require_main_organiser_login!
          set_locale(locale)
          set_page(page)
          @attributes = PARTICIPANT_ATTRIBUTES[:index]
          @participants = Participant.scoped
          if page == :"#{ ORG_PAGE_PREFIX }participants_to_approve"
            @participants = @participants.not_all_participations_approved
          end
          @participants = @participants.default_order.all
          @form_participant_id = id.to_i
          render_co_m_b_edit_participants
        end
      end

      get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }talks/edit/:id" do |id|
        require_main_organiser_login!
        set_locale(locale)
        set_page(:"#{ ORG_PAGE_PREFIX }talks")
        @attributes = TALK_ATTRIBUTES[:index]
        @talks = Talk.default_order.all
        @form_talk_id = id.to_i
        render_co_m_b_edit_talks
      end

      get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }hotels/edit/:id" do |id|
        require_main_organiser_login!
        set_locale(locale)
        set_page(:"#{ ORG_PAGE_PREFIX }hotels")
        @attributes = HOTEL_ATTRIBUTES[:index]
        @hotels = Hotel.default_order.all
        @form_hotel_id = id.to_i
        render_co_m_b_edit_hotels
      end

      [:"#{ ORG_PAGE_PREFIX }participants_to_approve", :"#{ ORG_PAGE_PREFIX }participants"].each do |page|
        get "#{ REQUEST_BASE_URL }#{ l }#{ page }/delete/:id" do |id|
          require_main_organiser_login!
          set_locale(locale)
          set_page(page)
          @participant = Participant.find(id)
          haml :"/pages/#{ ORG_PAGE_PREFIX }delete_participant.html"
        end
      end

      get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }talks/delete/:id" do |id|
        require_main_organiser_login!
        set_locale(locale)
        set_page(:"#{ ORG_PAGE_PREFIX }talks")
        @talk = Talk.find(id)
        haml :"/pages/#{ ORG_PAGE_PREFIX }delete_talk.html"
      end

      get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }hotels/delete/:id" do |id|
        require_main_organiser_login!
        set_locale(locale)
        set_page(:"#{ ORG_PAGE_PREFIX }hotels")
        @hotel = Hotel.find(id)
        haml :"/pages/#{ ORG_PAGE_PREFIX }delete_hotel.html"
      end
    end
  end

  get "#{ REQUEST_BASE_URL }login" do
    redirect fixed_url("/#{ ORG_PAGE_PREFIX }login")
  end

  get "#{ REQUEST_BASE_URL }logout" do
    cache_control :no_cache
    log_out
    redirect fixed_url('/')
  end

  # POST requests
  # -------------

  LOCALES.each do |locale|
    LOCALE_URL_FRAGMENTS[locale].each do |l|
      post "#{ REQUEST_BASE_URL }#{ l }registration" do
        set_locale(locale)

        # Filter attributes before mass assignement
        participant_attributes =
          participant_registration_attributes_from_param_hash(
            params[:participant])
        params[:debug] = participant_attributes
        @participant = Participant.new(participant_attributes)
        @participant.generate_pin

        if @participant.save
          # Send a notification to the organisers
          notifiy_organizers_by_email_about_registration_of(@participant)

          # Send a confirmation to the participant
          confirm_by_email_registration_of(@participant)

          flash.now[:success] = t('flash.resources.participants.create.success')
          haml :'/pages/registration_confirmation.html', :layout => :simple_layout
        else
          flash.now[:error] = t('flash.resources.participants.create.failure')
          @conferences = @participant.participations.map(&:conference)
          @participant.conferences = @conferences
          render_registration_page
        end
      end

      post "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }login" do
        user = User.find_by_username(params[:username])
        if user && user.accept_password?(params[:password])
          log_in(user)
          redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }")
        else
          flash[:error] = t('flash.sessions.log_in.failure')
          redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }login")
        end
      end
    end
  end

  # PUT requests
  # ------------

  LOCALES.each do |locale|
    LOCALE_URL_FRAGMENTS[locale].each do |l|

      [:"#{ ORG_PAGE_PREFIX }participants_to_approve",
       :"#{ ORG_PAGE_PREFIX }participants"
      ].each do |page|
        put "#{ REQUEST_BASE_URL }#{ l }#{ page }/:id" do |id|
          require_organiser_login!
          @participant = Participant.find(id)
          case params[:button]
          when 'approve'
            @participant.approved = true
          when 'disapprove'
            @participant.approved = false
          when 'update'
            require_main_organiser_login!
            participant_attributes = params[:participant]
            participant_attributes.each_pair { |k, v|
              participant_attributes[k] = nil if v.empty?
            }
            participant_attributes[:talk_proposal_attributes].tap { |h|
              h.delete_if { |_, v| v.empty? }
              h[:_destroy] = true if h.empty?
            }
            @participant.update_attributes(participant_attributes)
          end
          @participant.save!

          if page == :"#{ ORG_PAGE_PREFIX }participants_to_approve"
            redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }participants_to_approve#participant_#{ @participant.id }")
          else
            redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }participants#participant_#{ @participant.id }")
          end
        end
      end

      put "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }talk_proposals/:id" do |id|
        require_main_organiser_login!
        @talk_proposal = TalkProposal.find(id)
        case params[:button]
        when 'accept'
          @talk_proposal.accept
        when 'update'
          talk_proposal_attributes = params[:talk_proposal]
          talk_proposal_attributes.each_paire { |k, v|
            talk_proposal_attributes[k] = nil if v.empty?
          }
          @talk_proposal.update_attributes(talk_proposal_attributes)
        end
        @talk_proposal.save!
        redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }participants#participant_#{ @talk_proposal.participant_id }")
      end

      put "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }talks/:id" do |id|
        require_main_organiser_login!
        @talk = Talk.find(id)
        talk_attributes = params[:talk]
        talk_attributes.each_pair { |k, v|
          talk_attributes[k] = nil if v.empty?
        }
        @talk.update_attributes(talk_attributes)
        @talk.save!

        redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }talks#talk_#{ @talk.id }")
      end

      put "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }hotels/:id" do |id|
        require_main_organiser_login!
        @hotel = Hotel.find(id)
        hotel_attributes = params[:hotel]
        hotel_attributes.each_pair { |k, v|
          hotel_attributes[k] = nil if v.empty?
        }
        @hotel.update_attributes(hotel_attributes)
        @hotel.save!

        redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }hotels#hotel_#{ @hotel.id }")
      end
    end
  end

  # DELETE requests
  # ------------

  LOCALES.each do |locale|
    LOCALE_URL_FRAGMENTS[locale].each do |l|
      [:"#{ ORG_PAGE_PREFIX }participants_to_approve", :"#{ ORG_PAGE_PREFIX }participants"].each do |page|
        delete "#{ REQUEST_BASE_URL }#{ l }#{ page }/:id" do |id|
          require_main_organiser_login!
          Participant.find(id).destroy
          redirect fixed_url("/#{ locale }/#{ page }")
        end
      end

      delete "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }talks/:id" do |id|
        require_main_organiser_login!
        Talk.find(id).destroy
        redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }talks")
      end

      delete "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }hotels/:id" do |id|
        require_main_organiser_login!
        Hotel.find(id).destroy
        redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }hotels")
      end
    end
  end

  # View helpers
  # ============
  #
  require_relative 'helpers'
  helpers Helpers

  # Private methods
  # ===============
  #
  private

    def set_locale(locale)
      I18n.locale = @locale = locale
      @other_locales = LOCALES.reject { |l| l == @locale }
    end

    def set_page(page)
      @page = page
      @base_title = t('base_co_m_b_page_title')
      @title =
        "#{ @base_title } | #{ t(:title, :scope => page_i18n_scope(@page)) }"
    end

    def locale_from_user_input(suggested_locale)
      suggested_locale = suggested_locale.to_s.downcase
      LOCALES.find { |l| l.to_s == suggested_locale } || DEFAULT_LOCALE
    end

    def page_from_user_input(suggested_page)
      suggested_page = suggested_page.to_s.downcase
      PUBLIC_PAGES.find { |p| p.to_s == suggested_page } || COMB_HOME_PAGE
    end

    def render_registration_page
      set_page(:registration)

      if @conferences.nil? || @conferences.empty?
        @conferences = Conference.default_order
      end

      @field_labels = {}

      name = t('names.i_m_t')
      link_attributes =
        'href="http://www.math.univ-toulouse.fr/" target="_blank"'
      @field_labels[:i_m_t_member] =
        t('pages.registration.form.field_labels.i_m_t_member__for_html',
          :link_to_i_m_t => "<a #{ link_attributes }>#{ name }</a>")

      name = t('names.g_d_r_tresses')
      link_attributes =
        'href="http://tresses.math.cnrs.fr/" target="_blank"'
      @field_labels[:g_d_r_member] =
        t('pages.registration.form.field_labels.g_d_r_member__for_html',
          :link_to_g_d_r => "<a #{ link_attributes }>#{ name }</a>")

      PARTICIPANT_ATTRIBUTES[:registration].each do |attr|
        @field_labels[attr] ||=
          t(attr, :scope => 'pages.registration.form.field_labels')
      end

      haml :'/pages/registration.html', :layout => :simple_layout
    end

    def render_co_m_b_edit_participants
      @field_labels = Hash.new do |h, k|
        h[k] = capitalize_first_letter_of(Participant.human_attribute_name(k))
      end
      haml :"/pages/#{ ORG_PAGE_PREFIX }participants.html"
    end

    def render_co_m_b_edit_talks
      @field_labels = Hash.new do |h, k|
        h[k] = capitalize_first_letter_of(Talk.human_attribute_name(k))
      end
      haml :"/pages/#{ ORG_PAGE_PREFIX }talks.html"
    end

    def render_co_m_b_edit_hotels
      @field_labels = Hash.new do |h, k|
        h[k] = capitalize_first_letter_of(Hotel.human_attribute_name(k))
      end
      haml :"/pages/#{ ORG_PAGE_PREFIX }hotels.html"
    end

    def log_in(user)
      session[:user_id] = user.id
    end

    def log_out
      session.clear
    end

    def current_user
      User.find(session[:user_id].to_i)
    end

    def organiser_logged_in?
      (user = current_user) &&
        Set['organiser', 'main_organiser'].include?(user.role)
    end

    def main_organiser_logged_in?
      (user = current_user) && user.role == 'main_organiser'
    end

    def require_organiser_login!
      unless organiser_logged_in?
        # halt [ 401, 'Not Authorized' ]
        flash[:error] = t('flash.filters.require_organiser_login')
        redirect fixed_url("/#{ ORG_PAGE_PREFIX }login")
      end
    end

    def require_main_organiser_login!
      unless main_organiser_logged_in?
        # halt [ 401, 'Not Authorized' ]
        flash[:error] = t('flash.filters.require_main_organiser_login')
        redirect fixed_url("/#{ ORG_PAGE_PREFIX }login")
      end
    end

    def participant_registration_attributes_from_param_hash(hash)
      participant_attributes = {}.tap do |h|
        PARTICIPANT_ATTRIBUTES[:registration].each do |attr|
          value = hash[attr.to_s]
          h[attr] = value unless value.empty?
        end
      end

      participations_attributes = [].tap do |a|
        hash[:participations_attributes].each do |original_hash|
          unless original_hash['conference_id'].nil?
            a << {}.tap do |h|
              [:conference_id, :arrival_date, :departure_date].each do |attr|
                value = original_hash[attr.to_s]
                h[attr] = value unless value.empty?
              end
              h[:approved] = false
            end
          end
        end
      end

      @co_m_b_conference ||= Conference.co_m_b_conf

      co_m_b_participation_attributes =
        participations_attributes.find { |attributes|
          attributes[:conference_id].to_i == @co_m_b_conference.id
        }

      if co_m_b_participation_attributes
        co_m_b_talk_proposal_attributes = {}.tap do |h|
          original_hash = hash['co_m_b_participation_attributes']['talk_proposal_attributes']
          [:title, :abstract].each do |attr|
            value = original_hash[attr.to_s]
            h[attr] = value unless value.empty?
          end
        end
        co_m_b_participation_attributes[:talk_proposal_attributes] =
          co_m_b_talk_proposal_attributes
      end

      participant_attributes[:participations_attributes] =
        participations_attributes

      participant_attributes
    end

    def conferences_from_conference_ids_in_param_array(conference_ids)
      conference_ids = [] unless conference_ids.is_a?(Array)
      conference_ids.map!(&:to_i)
      Conference.default_order.select { |conf|
        conference_ids.include? conf.id
      }
    end

    if production?
      EMAIL_TO_ORGANISERS_BASIC_ATTRIBUTES =
        { :from => 'no-reply.top-geom-conf-2013@math.univ-toulouse.fr',
          :via  => :smtp }
      COMB_ORGANISERS_EMAIL = 'comb@math.univ-toulouse.fr'
      OTHER_ORGNISERS_EMAIL =
        'barraud@math.univ-toulouse.fr, niederkr@math.univ-toulouse.fr'
    else
      EMAIL_TO_ORGANISERS_BASIC_ATTRIBUTES =
        { :from => 'no-reply@localhost',
          :via  => :sendmail }
      COMB_ORGANISERS_EMAIL = "#{ ENV['USER'] }@localhost"
      OTHER_ORGNISERS_EMAIL = COMB_ORGANISERS_EMAIL
    end

    def organizer_notification_email_addresses(participations)
      co_m_b_conference_id = Conference.co_m_b_conf.id
      other_conference_ids =
        Set[:intro_conf, :g_e_s_t_a_conf, :llagone_conf].map { |idenitfier|
          Conference.public_send(idenitfier).id
        }
      addresses = []
      conference_ids = participations.map(&:conference_id)
      if conference_ids.any? { |id| other_conference_ids.include?(id) }
        addresses << OTHER_ORGNISERS_EMAIL
      end
      if conference_ids.include?(co_m_b_conference_id)
        addresses << COMB_ORGANISERS_EMAIL
      end
      addresses.join(', ')
    end

    def notifiy_organizers_by_email_about_registration_of(participant)
      email_addresses =
        organizer_notification_email_addresses(participant.participations)
      email_subject =
        "CTT 2013:  #{ participant.full_name_with_affiliation }"\
        "  has registered"
      email_html_body =
        haml(:'/email/registration_notification.html', :layout => false)
      email_body = ReverseMarkdown.parse email_html_body
      email_contents = { :subject   => email_subject,
                         :body      => email_body,
                         :html_body => email_html_body }

      email_attributes = EMAIL_TO_ORGANISERS_BASIC_ATTRIBUTES.dup
      email_attributes.merge!(email_contents)
      email_attributes[:to] = email_addresses
      Pony.mail email_attributes
    end

    if production?
      EMAIL_TO_PARTICIPANT_BASIC_ATTRIBUTES =
        { :from     => 'no-reply.top-geom-conf-2013@math.univ-toulouse.fr',
          :reply_to => 'comb@math.univ-toulouse.fr',
          :via      => :smtp }
    else
      EMAIL_TO_PARTICIPANT_BASIC_ATTRIBUTES =
        { :from     => 'no-reply@localhost',
          :reply_to => 'comb@math.univ-toulouse.fr',
          :via      => :sendmail }
    end

    def confirm_by_email_registration_of(participant)
      email_html_body =
        haml(:'/email/registration_confirmation.html', :layout => false)
      email_body = ReverseMarkdown.parse email_html_body
      email_contents = {
        :subject   => "CTT 2013 registration confirmation",
        :body      => email_body,
        :html_body => email_html_body }

      email_attributes = EMAIL_TO_PARTICIPANT_BASIC_ATTRIBUTES.dup
      email_attributes.merge!(email_contents)
      email_attributes[:to] = participant.email

      # XXX: for testing only
      if self.class.development?
        email_attributes[:to] = "#{ ENV['USER'] }@localhost"
      end

      Pony.mail email_attributes
    end

end

if __FILE__ == $0
  CTT2013.connect_database
  CTT2013.run!
end

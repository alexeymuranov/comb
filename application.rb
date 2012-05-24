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

  # Settings
  # ========

  # Host-specific constants
  if production?
    # For IMT web site
    BASE_URL = '/top-geom-conf-2013/'
    REQUEST_BASE_URL = '/'
    # EMAIL_TO_ORGANISERS_BASIC_ATTRIBUTES =
    #   { :to   => 'comb@math.univ-toulouse.fr',
    #     :from => 'no-reply.ctt2013-registration@math.univ-toulouse.fr',
    #     :via  => :smtp }
    EMAIL_TO_ORGANISERS_BASIC_ATTRIBUTES =
      { :to   => 'muranov@math.univ-toulouse.fr',
        :from => 'no-reply.ctt2013-registration@math.univ-toulouse.fr',
        :via  => :smtp }
    EMAIL_TO_PARTICIPANT_BASIC_ATTRIBUTES =
      { :from     => 'no-reply.ctt2013-registration@math.univ-toulouse.fr',
        :reply_to => 'comb@math.univ-toulouse.fr',
        :via      => :smtp }
  else
    # For localhost
    REQUEST_BASE_URL = BASE_URL = '/'
    EMAIL_TO_ORGANISERS_BASIC_ATTRIBUTES =
      { :to   => "#{ ENV['USER'] }@localhost",
        :from => 'no-reply@localhost',
        :via  => :sendmail }
    EMAIL_TO_PARTICIPANT_BASIC_ATTRIBUTES =
      { :from     => 'no-reply@localhost',
        :reply_to => 'comb@math.univ-toulouse.fr',
        :via      => :sendmail }
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
      :arrival_date, :departure_date,
      :funding_requests, :special_requests,
      :talk_proposal_attributes ]
  PARTICIPANT_ATTRIBUTES[:show] = PARTICIPANT_ATTRIBUTES[:index] =
    [ :first_name, :last_name, :email, :affiliation,
      :academic_position,
      :country, :city, :post_code, :street_address, :phone,
      :i_m_t_member, :g_d_r_member,
      :invitation_needed, :visa_needed,
      :arrival_date, :departure_date,
      :funding_requests, :special_requests,
      :approved, :committee_comments ]

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
                   :useful_links ]

  STATIC_PUBLIC_PAGES = Set[ :index,
                             :program,
                             :scientific_committee,
                             :organising_committee,
                             :directions_to_get_here,
                             :funding,
                             :contacts,
                             :accommodation,
                             :useful_links ]

  ORGANISER_CONNEXION_PAGES = [ :'org/participants/to_approve',
                                :'org/participants',
                                :'org/talks',
                                :'org/hotels' ]

  LOCALE_URL_FRAGMENTS = {}.tap { |h| LOCALES.each { |l| h[l] = ["#{ l }/"] } }
  LOCALE_URL_FRAGMENTS[DEFAULT_LOCALE] << ''

  # LOCALE_URL_FRAGMENT_MAP = { 'fr' => :fr, 'en' => :en, '' => :fr } # this is not used yet

  DEFAULT_PAGE = PUBLIC_PAGES[0]
  PAGE_URL_FRAGMENTS = {}.tap { |h| PUBLIC_PAGES.each { |p| h[p] = [p.to_s] } }
  PAGE_URL_FRAGMENTS[DEFAULT_PAGE] << ''

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

  LOCALES.each do |locale|
    LOCALE_URL_FRAGMENTS[locale].each do |l|
      PAGE_URL_FRAGMENTS[:registration].each do |p|
        # A page that uses models
        get "#{ REQUEST_BASE_URL }#{ l }#{ p }" do
          # @participant = Participant.new :arrival_date   => '2013-06-23',
          #                                :departure_date => '2013-06-28'
          @participant = Participant.new
          render_registration_page(locale)
        end
      end

      PAGE_URL_FRAGMENTS[:participants].each do |p|
        # A page that needs access to the database
        get "#{ REQUEST_BASE_URL }#{ l }#{ p }" do
          set_locale(locale)
          set_page(:participants)

          @participants = Participant.approved.default_order.all

          haml :'/pages/participants.html', :layout => :layout
        end
      end

      get "#{ REQUEST_BASE_URL }#{ l }org/login" do
        set_locale(locale)
        set_page(:'org/login')
        haml :'/pages/organiser_connexion/login.html'
      end

      get "#{ REQUEST_BASE_URL }#{ l }logout" do
        cache_control :no_cache
        log_out
        redirect fixed_url("/#{ locale }/")
      end

      get "#{ REQUEST_BASE_URL }#{ l }org/" do
        require_organiser_login!
        redirect fixed_url("/#{ locale }/org/participants/to_approve")
      end

      [:'org/participants/to_approve', :'org/participants'].each do |page|
        get "#{ REQUEST_BASE_URL }#{ l }#{ page }" do
          require_organiser_login!
          set_locale(locale)
          set_page(page)
          @attributes = PARTICIPANT_ATTRIBUTES[:index]
          @participants = Participant.scoped
          if page == :'org/participants/to_approve'
            @participants = @participants.not_approved
          end
          @participants = @participants.default_order.all
          haml :'/pages/organiser_connexion/participants.html'
        end
      end

      get "#{ REQUEST_BASE_URL }#{ l }org/talks" do
        require_organiser_login!
        set_locale(locale)
        set_page(:'org/talks')
        @attributes = TALK_ATTRIBUTES[:index]
        @talks = Talk.default_order.all
        haml :'/pages/organiser_connexion/talks.html'
      end

      get "#{ REQUEST_BASE_URL }#{ l }org/hotels" do
        require_organiser_login!
        set_locale(locale)
        set_page(:'org/hotels')
        @attributes = HOTEL_ATTRIBUTES[:index]
        @hotels = Hotel.default_order.all
        haml :'/pages/organiser_connexion/hotels.html'
      end

      [:'org/participants/to_approve', :'org/participants'].each do |page|
        get "#{ REQUEST_BASE_URL }#{ l }#{ page }/edit/:id" do |id|
          require_main_organiser_login!
          set_locale(locale)
          set_page(page)
          @attributes = PARTICIPANT_ATTRIBUTES[:index]
          @participants = Participant.scoped
          if page == :'org/participants/to_approve'
            @participants = @participants.not_approved
          end
          @participants = @participants.default_order.all
          @form_participant_id = id.to_i
          render_edit_participants
        end
      end

      get "#{ REQUEST_BASE_URL }#{ l }org/talks/edit/:id" do |id|
        require_main_organiser_login!
        set_locale(locale)
        set_page(:'org/talks')
        @attributes = TALK_ATTRIBUTES[:index]
        @talks = Talk.default_order.all
        @form_talk_id = id.to_i
        render_edit_talks
      end

      get "#{ REQUEST_BASE_URL }#{ l }org/hotels/edit/:id" do |id|
        require_main_organiser_login!
        set_locale(locale)
        set_page(:'org/hotels')
        @attributes = HOTEL_ATTRIBUTES[:index]
        @hotels = Hotel.default_order.all
        @form_hotel_id = id.to_i
        render_edit_hotels
      end

      [:'org/participants/to_approve', :'org/participants'].each do |page|
        get "#{ REQUEST_BASE_URL }#{ l }#{ page }/delete/:id" do |id|
          require_main_organiser_login!
          set_locale(locale)
          set_page(page)
          @participant = Participant.find(id)
          haml :'/pages/organiser_connexion/delete_participant.html'
        end
      end

      get "#{ REQUEST_BASE_URL }#{ l }org/talks/delete/:id" do |id|
        require_main_organiser_login!
        set_locale(locale)
        set_page(:'org/talks')
        @talk = Talk.find(id)
        haml :'/pages/organiser_connexion/delete_talk.html'
      end

      get "#{ REQUEST_BASE_URL }#{ l }org/hotels/delete/:id" do |id|
        require_main_organiser_login!
        set_locale(locale)
        set_page(:'org/hotels')
        @hotel = Hotel.find(id)
        haml :'/pages/organiser_connexion/delete_hotel.html'
      end
    end
  end

  get "#{ REQUEST_BASE_URL }login" do
    redirect fixed_url('/org/login')
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
      PAGE_URL_FRAGMENTS[:registration].each do |p|
        post "#{ REQUEST_BASE_URL }#{ l }#{ p }" do
          set_locale(locale)

          # Filter attributes before mass assignement
          participant_attributes = {}.tap do |h|
            original_hash = params[:participant]
            [ :first_name, :last_name, :email,
              :affiliation, :academic_position,
              :country, :city, :post_code, :street_address, :phone,
              :i_m_t_member, :g_d_r_member,
              :invitation_needed, :visa_needed,
              :arrival_date, :departure_date,
              :funding_requests, :special_requests,
              :talk_proposal_attributes
            ].each do |attr|
              value = original_hash[attr.to_s]
              h[attr] = value unless value.empty?
            end
          end
          talk_proposal_attributes = {}.tap do |h|
            original_hash = participant_attributes[:talk_proposal_attributes]
            [:title, :abstract].each do |attr|
              value = original_hash[attr.to_s]
              h[attr] = value unless value.empty?
            end
          end
          participant_attributes[:talk_proposal_attributes] =
            talk_proposal_attributes
          participant_attributes[:approved] = false
          @participant = Participant.new(participant_attributes)
          @participant.generate_pin

          if @participant.save
            # Send a notification to the organisers
            email_subject =
              "CTT 2013:  #{ @participant.full_name_with_affiliation }"\
              "  has registered"
            email_html_body =
              haml(:'/email/registration_notification.html', :layout => false)
            email_contents = { :subject   => email_subject,
                               :body      => @participant.to_yaml,
                               :html_body => email_html_body }

            email_attributes = EMAIL_TO_ORGANISERS_BASIC_ATTRIBUTES.dup
            email_attributes.merge!(email_contents)
            Pony.mail email_attributes

            # Send a confirmation to the participant
            email_body =
              ::File.read(
                ::File.join(
                  settings.views,
                  "text/#{ locale }/registration_confirmation.md"),
                :encoding => 'utf-8:utf-8')
            email_html_body =
              haml(:'/email/registration_confirmation.html', :layout => false)
            email_contents = {
              :subject   => "CTT 2013 registration confirmation",
              :body      => email_body,
              :html_body => email_html_body }

            email_attributes = EMAIL_TO_PARTICIPANT_BASIC_ATTRIBUTES.dup
            email_attributes.merge!(email_contents)
            email_attributes[:to] = @participant.email

            # XXX: for testing only
            if development?
              email_attributes[:to] = "#{ ENV['USER'] }@localhost"
            end

            Pony.mail email_attributes

            # XXX: Registration is not ready to use in production
            if self.class.production?
              flash[:notice] =
                "The registration is not open yet, please try again when the site is ready to use."
            else
              flash[:success] = t('flash.resources.participants.create.success')
            end
            redirect fixed_url("/#{ locale }/")
          else
            flash.now[:error] = t('flash.resources.participants.create.failure')
            render_registration_page(locale)
          end
        end
      end

      post "#{ REQUEST_BASE_URL }#{ l }org/login" do
        user = User.find_by_username(params[:username])
        if user && user.accept_password?(params[:password])
          log_in(user)
          redirect fixed_url("/#{ locale }/org/")
        else
          flash[:error] = t('flash.sessions.log_in.failure')
          redirect fixed_url("/#{ locale }/org/login")
        end
      end
    end
  end

  # PUT requests
  # ------------

  LOCALES.each do |locale|
    LOCALE_URL_FRAGMENTS[locale].each do |l|

      [:'org/participants/to_approve', :'org/participants'].each do |page|
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

          if page == :'org/participants/to_approve'
            redirect fixed_url("/#{ locale }/org/participants/to_approve#participant_#{ @participant.id }")
          else
            redirect fixed_url("/#{ locale }/org/participants#participant_#{ @participant.id }")
          end
        end
      end

      put "#{ REQUEST_BASE_URL }#{ l }org/talk_proposals/:id" do |id|
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
        redirect fixed_url("/#{ locale }/org/participants#participant_#{ @talk_proposal.participant_id }")
      end

      put "#{ REQUEST_BASE_URL }#{ l }org/talks/:id" do |id|
        require_main_organiser_login!
        @talk = Talk.find(id)
        talk_attributes = params[:talk]
        talk_attributes.each_pair { |k, v|
          talk_attributes[k] = nil if v.empty?
        }
        @talk.update_attributes(talk_attributes)
        @talk.save!

        redirect fixed_url("/#{ locale }/org/talks#talk_#{ @talk.id }")
      end

      put "#{ REQUEST_BASE_URL }#{ l }org/hotels/:id" do |id|
        require_main_organiser_login!
        @hotel = Hotel.find(id)
        hotel_attributes = params[:hotel]
        hotel_attributes.each_pair { |k, v|
          hotel_attributes[k] = nil if v.empty?
        }
        @hotel.update_attributes(hotel_attributes)
        @hotel.save!

        redirect fixed_url("/#{ locale }/org/hotels#hotel_#{ @hotel.id }")
      end
    end
  end

  # DELETE requests
  # ------------

  LOCALES.each do |locale|
    LOCALE_URL_FRAGMENTS[locale].each do |l|
      [:'org/participants/to_approve', :'org/participants'].each do |page|
        delete "#{ REQUEST_BASE_URL }#{ l }#{ page }/:id" do |id|
          require_main_organiser_login!
          Participant.find(id).destroy
          redirect fixed_url("/#{ locale }/#{ page }")
        end
      end

      delete "#{ REQUEST_BASE_URL }#{ l }org/talks/:id" do |id|
        require_main_organiser_login!
        Talk.find(id).destroy
        redirect fixed_url("/#{ locale }/org/talks")
      end

      delete "#{ REQUEST_BASE_URL }#{ l }org/hotels/:id" do |id|
        require_main_organiser_login!
        Hotel.find(id).destroy
        redirect fixed_url("/#{ locale }/org/hotels")
      end
    end
  end

  # View helpers
  # ============
  #
  require_relative 'helpers'

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
      @base_title = t('base_page_title')
      @title = "#{ @base_title } | #{ t(@page, :scope => 'page_titles') }"
    end

    def locale_from_user_input(suggested_locale)
      suggested_locale = suggested_locale.to_s.downcase
      LOCALES.find { |l| l.to_s == suggested_locale } || DEFAULT_LOCALE
    end

    def page_from_user_input(suggested_page)
      suggested_page = suggested_page.to_s.downcase
      PUBLIC_PAGES.find { |p| p.to_s == suggested_page } || DEFAULT_PAGE
    end

    def render_registration_page(locale)
      set_locale(locale)
      set_page(:registration)

      @field_labels = {}

      [ :first_name, :last_name, :email, :affiliation, :academic_position,
        :country, :city, :post_code, :street_address, :phone,
        :invitation_needed, :visa_needed, :arrival_date, :departure_date,
        :funding_requests, :special_requests
      ].each do |attr|
        @field_labels[attr] =
          t(attr, :scope => 'pages.registration.form.field_labels')
      end

      name = t('names.i_m_t')
      @field_labels[:i_m_t_member] =
        t('pages.registration.form.field_labels.i_m_t_member',
          :link_to_i_m_t =>
            "<a href='http://www.math.univ-toulouse.fr/' target='_blank'>#{ name }</a>")

      name = t('names.g_d_r_tresses')
      @field_labels[:g_d_r_member] =
        t('pages.registration.form.field_labels.g_d_r_member',
          :link_to_g_d_r =>
            "<a href='http://tresses.math.cnrs.fr' target='_blank'>#{ name }</a>")

      haml :'/pages/registration.html', :layout => :layout
    end

    def render_edit_participants
      @field_labels = Hash.new do |h, k|
        h[k] = capitalize_first_letter_of(Participant.human_attribute_name(k))
      end
      haml :'/pages/organiser_connexion/participants.html'
    end

    def render_edit_talks
      @field_labels = Hash.new do |h, k|
        h[k] = capitalize_first_letter_of(Talk.human_attribute_name(k))
      end
      haml :'/pages/organiser_connexion/talks.html'
    end

    def render_edit_hotels
      @field_labels = Hash.new do |h, k|
        h[k] = capitalize_first_letter_of(Hotel.human_attribute_name(k))
      end
      haml :'/pages/organiser_connexion/hotels.html'
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
        redirect fixed_url('/org/login')
      end
    end

    def require_main_organiser_login!
      unless main_organiser_logged_in?
        # halt [ 401, 'Not Authorized' ]
        flash[:error] = t('flash.filters.require_main_organiser_login')
        redirect fixed_url('/org/login')
      end
    end

end

if __FILE__ == $0
  CTT2013.connect_database
  CTT2013.run!
end

# encoding: UTF-8 (magic comment)

class CTT2013 < Sinatra::Base

  # Handlers
  # ========
  #
  COMMON_HOME_PAGE = :'common/index.php'

  COMB_PAGE_PREFIX = :'ldtg-mb/'

  PUBLIC_PAGES =
    [ :index,
      :program,
      :scientific_committee,
      :organising_committee,
      :directions_to_get_here,
      :funding,
      :contacts,
      :accommodation,
      :participants,
      :registration, # only displays that registration is closed
      :useful_links
    ].map{|p| :"#{ COMB_PAGE_PREFIX }#{ p }" }

  STATIC_PUBLIC_PAGES =
    Set[ :index,
         :program,
         :scientific_committee,
         :organising_committee,
         :directions_to_get_here,
         :funding,
         :contacts,
         :registration,
         :useful_links
       ].map{|p| :"#{ COMB_PAGE_PREFIX }#{ p }" }

  COMB_HOME_PAGE = PUBLIC_PAGES[0]
  PAGE_URL_FRAGMENTS = PUBLIC_PAGES.reduce({}){|h, p| h[p] = [p.to_s]; h }
  PAGE_URL_FRAGMENTS[COMB_HOME_PAGE] << COMB_PAGE_PREFIX

  # Handle unmatched requests
  # -------------------------

  not_found do
    send_file ::File.join(settings.public_folder, '404.html')
  end

  # GET requests
  # ------------

  get "/stylesheets/application.css" do
    content_type :css, :charset => 'utf-8'
    scss :'/stylesheets/application.css'
  end

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    get "/#{ l }" do
      redirect fixed_url("/#{ COMMON_HOME_PAGE }?lang=#{ locale }")
    end
  end

  # # Registration is closed since 2013-05-01.
  # LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
  #   get "/#{ l }registration" do
  #     set_locale(locale)
  #     @participant = Participant.new
  #     @conferences = Conference.find(conference_ids_from_params)
  #     @conferences.each do |conf|
  #       @participant.participations.build(:conference => conf)
  #     end
  #     render_registration_page
  #   end
  # end

  STATIC_PUBLIC_PAGES.each do |page|
    page_file = :"/pages/#{ page }.html"
    LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
      PAGE_URL_FRAGMENTS[page].each do |p|
        get "/#{ l }#{ p }" do
          set_locale(locale)
          set_page(page)
          haml page_file, :layout => :layout
        end
      end
    end
  end

  co_m_b_accommodation_page = :"#{ COMB_PAGE_PREFIX }accommodation"
  page_file = :"/pages/#{ co_m_b_accommodation_page }.html"
  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    PAGE_URL_FRAGMENTS[co_m_b_accommodation_page].each do |p|
      get "/#{ l }#{ p }" do
        set_locale(locale)
        set_page(co_m_b_accommodation_page)

        @hotels = Hotel.default_order

        haml page_file, :layout => :layout
      end
    end
  end

  # Plain participant lists
  get "/data/participants/by_conference/:conf_identifier" do |conf_identifier|
    unless conference = Conference.where(:identifier => conf_identifier).first
      halt
    end

    @participants = conference.participants.approved.default_order.all

    haml :"/pages/data/_participants", :layout => false
  end

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    participants_page = :"#{ COMB_PAGE_PREFIX }participants"
    PAGE_URL_FRAGMENTS[participants_page].each do |p|
      # A page that needs access to the database
      get "/#{ l }#{ p }" do
        set_locale(locale)
        set_page(participants_page)

        @participants =
          Conference.co_m_b_conf.participants.approved.default_order.all

        haml :"/pages/#{ participants_page }.html", :layout => :layout
      end
    end
  end

  # POST requests
  # -------------

  # # Registration is closed since 2013-05-01.
  # LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
  #   post "/#{ l }registration" do
  #     set_locale(locale)

  #     # Filter attributes before mass assignment
  #     participant_attributes =
  #       participant_attributes_from_params_for(:registration)
  #     # params[:debug_participant_attributes] = participant_attributes
  #     @participant = Participant.new(participant_attributes)
  #     @participant.generate_pin

  #     if @participant.save
  #       # Send a notification to the organisers
  #       notifiy_organizers_by_email_about_registration_of(@participant)

  #       # Send a confirmation to the participant
  #       confirm_by_email_registration_of(@participant)

  #       flash.now[:success] = t('flash.resources.participants.create.success')
  #       haml :'/pages/registration_confirmation.html', :layout => :simple_layout
  #     else
  #       flash.now[:error] = t('flash.resources.participants.create.failure')
  #       @conferences = Conference.find(conference_ids_from_params)
  #       render_registration_page
  #     end
  #   end

  # Private methods
  # ===============
  #
  private

    # def render_registration_page
    #   set_page(:registration)

    #   if @conferences.nil? || @conferences.empty?
    #     @conferences = Conference.default_order
    #   end

    #   @field_labels = {}

    #   name = t('names.i_m_t')
    #   link_attributes =
    #     'href="http://www.math.univ-toulouse.fr/" target="_blank"'
    #   @field_labels[:i_m_t_member] =
    #     t('pages.registration.form.field_labels.i_m_t_member__for_html',
    #       :link_to_i_m_t => "<a #{ link_attributes }>#{ name }</a>")

    #   name = t('names.g_d_r_tresses')
    #   link_attributes =
    #     'href="http://tresses.math.cnrs.fr/" target="_blank"'
    #   @field_labels[:g_d_r_member] =
    #     t('pages.registration.form.field_labels.g_d_r_member__for_html',
    #       :link_to_g_d_r => "<a #{ link_attributes }>#{ name }</a>")

    #   PARTICIPANT_ATTRIBUTE_NAMES_FOR[:registration].each do |attr|
    #     @field_labels[attr] ||=
    #       t(attr, :scope => 'pages.registration.form.field_labels')
    #   end

    #   haml :'/pages/registration.html', :layout => :simple_layout
    # end

    if production?
      EMAIL_TO_ORGANISERS_BASIC_ATTRIBUTES =
        { :from => 'no-reply.top-geom-conf-2013@math.univ-toulouse.fr',
          :via  => :smtp }
      COMB_ORGANISERS_EMAILS = ['comb@math.univ-toulouse.fr']
      OTHER_ORGANISERS_EMAILS = ['niederkr@math.univ-toulouse.fr']
    else
      EMAIL_TO_ORGANISERS_BASIC_ATTRIBUTES =
        { :from => 'no-reply@localhost',
          :via  => :sendmail }
      COMB_ORGANISERS_EMAILS = ["#{ ENV['USER'] }@localhost"]
      OTHER_ORGANISERS_EMAILS = COMB_ORGANISERS_EMAILS
    end

    def organizer_notification_email_addresses(participations)
      conference_ids       = participations.map(&:conference_id)
      # co_m_b_conference_id = Conference.co_m_b_conf.id
      other_conference_ids =
        Set[:intro_conf, :g_e_s_t_a_conf, :llagone_conf].map { |idenitfier|
          Conference.public_send(idenitfier).id
        }

      [*COMB_ORGANISERS_EMAILS].tap do |addresses|
        if conference_ids.any?{|id| other_conference_ids.include?(id) }
          addresses.concat(OTHER_ORGANISERS_EMAILS)
        end
      end.join(', ')
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
      # if self.class.development?
      #   email_attributes[:to] = "#{ ENV['USER'] }@localhost"
      # end

      Pony.mail email_attributes
    end

end

# encoding: UTF-8 (magic comment)

class CTT2013 < Sinatra::Base

  # Handlers
  # ========
  #
  COMMON_HOME_PAGE = :'common/index.php'

  COMB_PAGE_PREFIX = :'ldtg-mb/'

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

  COMB_HOME_PAGE = PUBLIC_PAGES[0]
  PAGE_URL_FRAGMENTS = {}.tap { |h| PUBLIC_PAGES.each { |p| h[p] = [p.to_s] } }
  PAGE_URL_FRAGMENTS[COMB_HOME_PAGE] << COMB_PAGE_PREFIX

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

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    get "#{ REQUEST_BASE_URL }#{ l }" do
      redirect fixed_url("/#{ COMMON_HOME_PAGE }?lang=#{ locale }")
    end
  end

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    get "#{ REQUEST_BASE_URL }#{ l }registration" do
      set_locale(locale)
      @conferences = conferences_from_conference_ids_in_param_array(
                       params[:conference_ids])
      @participant = Participant.new(:conferences => @conferences)
      render_registration_page
    end
  end

  STATIC_PUBLIC_PAGES.each do |page|
    page_file = :"/pages/#{ page }.html"
    LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
      PAGE_URL_FRAGMENTS[page].each do |p|
        get "#{ REQUEST_BASE_URL }#{ l }#{ p }" do
          set_locale(locale)
          set_page(page)
          haml page_file, :layout => :layout
        end
      end
    end
  end

  co_m_b_registration_page = :"#{ COMB_PAGE_PREFIX }registration"
  page_file = :"/pages/#{ co_m_b_registration_page }.html"
  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    PAGE_URL_FRAGMENTS[co_m_b_registration_page].each do |p|
      get "#{ REQUEST_BASE_URL }#{ l }#{ p }" do
        set_locale(locale)
        set_page(co_m_b_registration_page)
        haml page_file, :layout => :layout
      end
    end
  end

  # Plain participant lists
  get "#{ REQUEST_BASE_URL }data/participants/by_conference/:conf_identifier" do |conf_identifier|
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
      get "#{ REQUEST_BASE_URL }#{ l }#{ p }" do
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

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    post "#{ REQUEST_BASE_URL }#{ l }registration" do
      set_locale(locale)

      # Filter attributes before mass assignment
      participant_attributes =
        participant_registration_attributes_from_param_hash(
          params[:participant])
      # params[:debug] = participant_attributes
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
  end

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

    def participant_registration_attributes_from_param_hash(hash)
      attr_names = PARTICIPANT_ATTRIBUTES[:registration]

      participant_attributes = {}.tap do |h|
        attr_names.each do |attr|
          value = hash[attr.to_s]
          h[attr] = value unless value.empty?
        end
      end

      participations_attributes = [].tap do |a|
        hash['participations_attributes'].each_value do |participation_hash|
          unless participation_hash['conference_id'].nil?
            a << {}.tap do |h|
              [ :conference_id, :arrival_date, :departure_date,
                :_destroy
              ].each do |attr|
                value = participation_hash[attr.to_s]
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
          original_hash =
            hash['co_m_b_participation_attributes']['talk_proposal_attributes']
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
      Conference.where(:id => conference_ids).default_order
    end

    if production?
      EMAIL_TO_ORGANISERS_BASIC_ATTRIBUTES =
        { :from => 'no-reply.top-geom-conf-2013@math.univ-toulouse.fr',
          :via  => :smtp }
      COMB_ORGANISERS_EMAIL = 'comb@math.univ-toulouse.fr'
      OTHER_ORGANISERS_EMAIL =
        'barraud@math.univ-toulouse.fr, niederkr@math.univ-toulouse.fr'
    else
      EMAIL_TO_ORGANISERS_BASIC_ATTRIBUTES =
        { :from => 'no-reply@localhost',
          :via  => :sendmail }
      COMB_ORGANISERS_EMAIL = "#{ ENV['USER'] }@localhost"
      OTHER_ORGANISERS_EMAIL = COMB_ORGANISERS_EMAIL
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
        addresses << OTHER_ORGANISERS_EMAIL
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
      # if self.class.development?
      #   email_attributes[:to] = "#{ ENV['USER'] }@localhost"
      # end

      Pony.mail email_attributes
    end

end

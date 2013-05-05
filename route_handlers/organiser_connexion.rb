# encoding: UTF-8 (magic comment)

class CTT2013 < Sinatra::Base

  # Authentication User model
  # =========================
  #

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
      block_given? ? @@users.each{|u| yield(u) } : @@users.each
    end

    def self.find_by_username(username)
      @@users.find{|u| u.username == username }
    end

    def self.find(id)
      @@users.find{|u| u.id == id }
    end
  end

  User.new('comb', 'organiser').password_hash =
    '6nKIQNNx4aVW9R5XQT/okSB6JcH3Sbb3b88Gjz5Nyt0='

  User.new('gestion', 'main_organiser').password_hash =
    'fqTJyyW7Hg2d90NkzmRPOVSb54LlxgeGMDxF6nmNRt8='

  # Handlers
  # ========
  #

  ORGANISER_CONNEXION_PAGES =
    [ :participants,
      :participants_with_talk_proposals,
      :talks,
      :hotels,
      :utilities
    ].map{|p| :"org/#{ p }" }


  ORGANISER_CONNEXION_UTILITY_TABS = {
    :graduate_students_approved =>
      'email_lists/graduate_students/approved',
    :graduate_students_not_all_participations_approved =>
      'email_lists/graduate_students/not_all_participations_approved',
    :talk_proposals_for_scientific_committee =>
      'talk_proposals_for_scientific_committee' }

  # Cache control
  before %r{/org/} do
    cache_control :no_cache
  end

  # GET requests
  # ------------

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    get "/#{ l }org/login" do
      set_locale(locale)
      set_page(:"org/login")
      haml :"/pages/org/login.html"
    end

    get "/#{ l }logout" do
      cache_control :no_cache
      log_out
      redirect fixed_url_with_locale("/org/login", locale)
    end

    get "/#{ l }org/" do
      require_organiser_login!

      redirect fixed_url_with_locale("/org/participants", locale)
    end

    PARTICIPANT_ATTRIBUTE_NAMES_FOR_INDEX =
      [:last_name, :first_name, :affiliation, :academic_position]

    PARTICIPANT_ATTRIBUTE_LABELS_FOR_INDEX =
      PARTICIPANT_ATTRIBUTE_NAMES_FOR_INDEX.map { |attr|
        DataPresentationHelpers::capitalize_first_letter_of(
          Participant.human_attribute_name(attr))
      }

    PARTICIPANT_ATTRIBUTE_PROCS_FOR_INDEX =
      PARTICIPANT_ATTRIBUTE_NAMES_FOR_INDEX.map(&:to_proc)

    [ :"org/participants",
      :"org/participants_with_talk_proposals"
    ].each do |page|
      get "/#{ l }#{ page }" do
        require_organiser_login!

        set_locale(locale)
        set_page(page)

        # Filtering.
        participants_filter   = participants_filter_from_params
        participations_filter = participations_filter_from_params
        filtered_participants =
          participants_scope_from_filters(
            :participants_filter   => participants_filter,
            :participations_filter => participations_filter)

        @filtering_values = {}
        if participants_filter
          @filtering_values[Participant.table_name] =
            participants_filter.filtering_values_as_simple_nested_hash
        end
        if participations_filter
          @filtering_values[Participation.table_name] =
            participations_filter.filtering_values_as_simple_nested_hash
        end
        @filtering_values.delete_if{|_, v| v.empty? }

        @filtering_by =
          [ [Participant,   :last_name, {:html_input_options => {:autofocus => true}}],
            [Participation, :conference, {:name_proc => :identifier.to_proc}],
            [Participant,   :academic_position],
            [Participant,   :invitation_needed],
            [Participant,   :visa_needed],
            [Participation, :approved] ]

        if page == :"org/participants_with_talk_proposals"
          filtered_participants =
            filtered_participants.joins(:talk_proposals).uniq.default_order
        end

        filtered_participants = filtered_participants.default_order

        @filtered_participants_count = filtered_participants.count

        # Pagination
        @view_parameters = pagination_parameters_from_params
        per_page    = @view_parameters[:per_page]
        active_page = @view_parameters[:page]
        @participants =
          filtered_participants.limit(per_page).offset(per_page * (active_page - 1))
        @view_parameters[:page_count] =
          ((@filtered_participants_count - 1) / per_page) + 1

        # Page content
        @attribute_headers = PARTICIPANT_ATTRIBUTE_LABELS_FOR_INDEX
        @attribute_procs = PARTICIPANT_ATTRIBUTE_PROCS_FOR_INDEX

        @participations_header =
          capitalize_first_letter_of(
            Participant.human_attribute_name(:participations))

        @participation_procs = Conference.default_order.map { |conf|
          lambda { |participant|
            participation =
              participant.participations.find{|p| p.conference == conf }
            participation ? (participation.approved? ? '✓' : '—') : '·'
          }
        }

        haml :"/pages/org/participants/index_all.html"
      end
    end

    get "/#{ l }org/participants/new" do
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"org/participants")

      @attribute_names   = PARTICIPANT_ATTRIBUTE_NAMES_FOR[:create]
      @association_names = [:participations, :talk_proposals]

      @participant = Participant.new

      if @association_names.include?(:participations)
        @conferences = Conference.default_order
      end

      haml :"/pages/org/participants/new_one.html"
    end

    PARTICIPANT_ATTRIBUTE_NAMES_FOR_SHOW =
      [ :first_name, :last_name, :email, :affiliation,
        :academic_position,
        :country, :city, :post_code, :street_address, :phone,
        :i_m_t_member, :g_d_r_member,
        :invitation_needed, :visa_needed,
        :funding_requests,
        :special_requests,
        :approved ]

    get "/#{ l }org/participants/:id" do |id|
      require_organiser_login!

      set_locale(locale)
      # set_page(:org/participants)

      id = id.to_i

      @attribute_names = PARTICIPANT_ATTRIBUTE_NAMES_FOR_SHOW

      @participant = Participant.find(id)

      haml :"/pages/org/participants/show_one.html"
    end

    get "/#{ l }org/participants/:id/edit" do |id|
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"org/participants")

      @attribute_names   = participant_attribute_names_from_params_for_edit
      @association_names = participant_association_names_from_params_for_edit

      @participant = Participant.find(id)

      if @association_names.include?(:participations)
        @conferences = Conference.default_order
      end

      haml :"/pages/org/participants/edit_one.html"
    end

    get "/#{ l }org/participants/:id/delete" do |id|
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"org/participants")

      @participant = Participant.find(id)
      haml :"/pages/org/participants/delete_one.html"
    end

    TALK_ATTRIBUTE_NAMES_FOR_INDEX =
      [ :translated_type_name, :speaker_name, :title,
        :date, :time, :room_or_auditorium ]

    TALK_ATTRIBUTE_LABELS_FOR_INDEX =
      TALK_ATTRIBUTE_NAMES_FOR_INDEX.map { |attr|
        DataPresentationHelpers::capitalize_first_letter_of(
          Talk.human_attribute_name(attr))
      }

    TALK_ATTRIBUTE_PROCS_FOR_INDEX =
      TALK_ATTRIBUTE_NAMES_FOR_INDEX.map(&:to_proc)

    get "/#{ l }org/talks" do
      require_organiser_login!

      set_locale(locale)
      set_page(:"org/talks")

      @talks = Talk.default_order.all

      # Page content
      @attribute_headers = TALK_ATTRIBUTE_LABELS_FOR_INDEX
      @attribute_procs = TALK_ATTRIBUTE_PROCS_FOR_INDEX

      haml :"/pages/org/talks/index_all.html"
    end

    get "/#{ l }org/talks/new" do
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:org/talks)

      @attribute_names = TALK_ATTRIBUTE_NAMES_FOR[:create]

      @talk = Talk.new

      haml :"/pages/org/talks/new_one.html"
    end

    TALK_ATTRIBUTE_NAMES_FOR_SHOW =
      [ :translated_type_name, :speaker_name, :title, :abstract,
        :date, :time, :room_or_auditorium ]

    get "/#{ l }org/talks/:id" do |id|
      require_organiser_login!

      set_locale(locale)
      # set_page(:org/talks)

      id = id.to_i

      @attribute_names = TALK_ATTRIBUTE_NAMES_FOR_SHOW

      @talk = Talk.find(id)

      haml :"/pages/org/talks/show_one.html"
    end

    get "/#{ l }org/talks/:id/edit" do |id|
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"org/talks")

      @attribute_names = TALK_ATTRIBUTE_NAMES_FOR[:update]
      @talk = Talk.find(id)
      haml :"/pages/org/talks/edit_one.html"
    end

    get "/#{ l }org/talks/:id/delete" do |id|
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"org/talks")

      @talk = Talk.find(id)
      haml :"/pages/org/talks/delete_one.html"
    end

    HOTEL_ATTRIBUTE_NAMES_FOR_INDEX = [:name, :address, :phone, :web_site]

    HOTEL_ATTRIBUTE_LABELS_FOR_INDEX =
      HOTEL_ATTRIBUTE_NAMES_FOR_INDEX.map { |attr|
        DataPresentationHelpers::capitalize_first_letter_of(
          Hotel.human_attribute_name(attr))
      }

    HOTEL_ATTRIBUTE_PROCS_FOR_INDEX =
      HOTEL_ATTRIBUTE_NAMES_FOR_INDEX.map(&:to_proc)

    get "/#{ l }org/hotels" do
      require_organiser_login!

      set_locale(locale)
      set_page(:"org/hotels")

      @hotels = Hotel.default_order.all

      # Page content
      @attribute_headers = HOTEL_ATTRIBUTE_LABELS_FOR_INDEX
      @attribute_procs = HOTEL_ATTRIBUTE_PROCS_FOR_INDEX

      haml :"/pages/org/hotels/index_all.html"
    end

    get "/#{ l }org/hotels/new" do
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:org/hotels)

      @attribute_names = HOTEL_ATTRIBUTE_NAMES_FOR[:create]

      @hotel = Hotel.new

      haml :"/pages/org/hotels/new_one.html"
    end

    HOTEL_ATTRIBUTE_NAMES_FOR_SHOW = [:name, :address, :phone, :web_site]

    get "/#{ l }org/hotels/:id" do |id|
      require_organiser_login!

      set_locale(locale)
      # set_page(:org/hotels)

      id = id.to_i

      @attribute_names = HOTEL_ATTRIBUTE_NAMES_FOR_SHOW

      @hotel = Hotel.find(id)

      haml :"/pages/org/hotels/show_one.html"
    end

    get "/#{ l }org/hotels/:id/edit" do |id|
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"org/hotels")

      @attribute_names = HOTEL_ATTRIBUTE_NAMES_FOR[:update]
      @hotel = Hotel.find(id)
      haml :"/pages/org/hotels/edit_one.html"
    end

    get "/#{ l }org/hotels/:id/delete" do |id|
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"org/hotels")

      @hotel = Hotel.find(id)
      haml :"/pages/org/hotel/delete_one.html"
    end

    get "/#{ l }org/utilities" do
      require_organiser_login!

      set_locale(locale)
      set_page(:"org/utilities")

      haml :"/pages/org/utilities_layout" do nil end
    end

    get "/#{ l }org/utilities/email_lists/graduate_students/:status" do |status|
      require_organiser_login!

      set_locale(locale)
      set_page(:"org/utilities")

      @participants = Participant.
        where(:academic_position => ['graduate student', 'doctorant(e)']).
        default_order

      case status
      when 'approved'
        @utility_tab = :graduate_students_approved
        @participants = @participants.approved
      when 'not_all_participations_approved'
        @utility_tab = :graduate_students_not_all_participations_approved
        @participants = @participants.not_all_participations_approved
      end

      haml :"/pages/org/utilities_layout" do
        haml :"/pages/org/participants/email_list",
             :layout => false
      end
    end

    get "/#{ l }org/utilities/talk_proposals_for_scientific_committee" do
      require_organiser_login!

      set_locale(locale)
      set_page(:"org/utilities")
      @utility_tab = :talk_proposals_for_scientific_committee

      @participants_with_talk_proposals =
        Participant.joins(:talk_proposals).uniq.default_order

      haml :"/pages/org/utilities_layout" do
        haml :"/pages/org/utilities/talk_proposals_for_scientific_committee.html",
             :layout => false
      end
    end

    get "/#{ l }org/articles/talk_proposals_for_scientific_committee" do
      require_organiser_login!

      set_locale(locale)

      @participants_with_talk_proposals =
        Participant.joins(:talk_proposals).uniq.default_order

      haml :"/pages/org/articles/talk_proposals_for_scientific_committee.html",
           :layout => :simple_layout
    end
  end

  get "/login" do
    redirect fixed_url("/org/login")
  end

  get "/logout" do
    cache_control :no_cache
    log_out
    redirect fixed_url('/')
  end

  PARTICIPANT_ATTRIBUTE_NAMES_FOR_DOWNLOAD =
    [ :last_name, :first_name, :email, :affiliation, :academic_position,
      :country, :city, :post_code, :street_address, :phone,
      :i_m_t_member, :g_d_r_member,
      :invitation_needed, :visa_needed, :special_requests ]

  PARTICIPANT_ATTRIBUTE_LABELS_FOR_DOWNLOAD =
    PARTICIPANT_ATTRIBUTE_NAMES_FOR_DOWNLOAD.map { |attr|
      DataPresentationHelpers::capitalize_first_letter_of(
        Participant.human_attribute_name(attr))
    }

  PARTICIPANT_ATTRIBUTE_PROCS_FOR_DOWNLOAD =
    PARTICIPANT_ATTRIBUTE_NAMES_FOR_DOWNLOAD.map { |attr|
      case Participant.attribute_type(attr)
      when :boolean
        lambda { |participant|
          attr.to_proc[participant] ? 'X' : nil
        }
      else
        attr.to_proc
      end
    }

  get "/download/participants.:format" do |format|
    require_organiser_login!

    attachment "filtered participants " +
               "#{ Time.now.strftime('%Y-%m-%d %k-%M') }.#{ format }"

    @headers = PARTICIPANT_ATTRIBUTE_LABELS_FOR_DOWNLOAD
    @attribute_procs = PARTICIPANT_ATTRIBUTE_PROCS_FOR_DOWNLOAD

    all_conferences = Conference.default_order.all

    @headers += all_conferences.map { |conf|
      [ conf.identifier,
        capitalize_first_letter_of(
          Participation.human_attribute_name(:committee_comments)) +
          " (#{ conf.identifier })" ]
    }.reduce(&:concat)

    @attribute_procs += all_conferences.map { |conf|
      [ lambda { |participant|
          participation =
            participant.participations.find{|p| p.conference == conf }
          if participation
            "(#{ participation.approved? ? 'X' : '-' }) " +
              "[#{ participation.arrival_date } .. #{ participation.departure_date }]"
          end
        },

        lambda { |participant|
          participation =
            participant.participations.find{|p| p.conference == conf }
          if participation
            participation.committee_comments
          end
        } ]
    }.reduce(&:concat)

    # Filtering
    @participants =
      participants_scope_from_filters(
        :participants_filter   => participants_filter_from_params,
        :participations_filter => participations_filter_from_params)

    @participants = @participants.default_order

    case format
    when 'csv'
      content_type 'text/csv', :charset => 'utf-8'
      csv_from_collection(@participants, @attribute_procs, @headers)
    end
  end

  # POST requests
  # -------------

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    post "/#{ l }org/participants/" do
      require_main_organiser_login!

      set_locale(locale)

      participant_attributes =
        participant_attributes_from_params_for(:create)

      @participant = Participant.new(participant_attributes)

      if @participant.save
        flash[:success] = t('flash.resources.participants.create.success')
        redirect fixed_url_with_locale("/org/participants/#{ @participant.id }", locale)
      else
        set_page(:"org/participants")

        flash.now[:error] = t('flash.resources.participants.update.failure')
        @attribute_names = PARTICIPANT_ATTRIBUTE_NAMES_FOR[:create]
        @association_names = [:participations, :talk_proposals]

        if @association_names.include?(:participations)
          @conferences = Conference.default_order
        end

        haml :"/pages/org/participants/new_one.html"
      end
    end

    post "/#{ l }org/login" do
      user = User.find_by_username(params[:username])
      if user && user.accept_password?(params[:password])
        log_in(user)
        if session.key?(:return_to)
          redirect fixed_url(session[:return_to])
          session.delete(:return_to)
        else
          redirect fixed_url_with_locale("/org/participants", locale)
        end
      else
        flash[:error] = t('flash.sessions.log_in.failure')
        redirect fixed_url_with_locale("/org/login", locale)
      end
    end

    post "/#{ l }org/talks/" do
      require_main_organiser_login!

      set_locale(locale)

      talk_attributes = talk_attributes_from_params_for(:create)
      case talk_attributes[:type]
      when 'ParallelTalk'
        @talk = ParallelTalk.new(talk_attributes)
      when 'PlenaryTalk'
        @talk = PlenaryTalk.new(talk_attributes)
      else
        @talk = Talk.new(talk_attributes)
      end

      participation_attributes =
        talk_participation_attributes_from_params_for_create
      participation = Participation.where(participation_attributes).first

      # NOTE: This is for safety only.
      # Not needed if the database is known to not contain any abandoned
      # 'participations'.
      if participation.participant.nil?
        participation = nil
      end

      @talk.conference_participation = participation

      if @talk.save
        flash[:success] = t('flash.resources.talks.create.success')
        redirect fixed_url_with_locale("/org/talks/#{ @talk.id }", locale)
      else
        flash.now[:error] = t('flash.resources.talks.create.failure')
        haml :"/pages/org/talks/new_one.html"
      end
    end

    post "/#{ l }org/hotels/" do
      require_main_organiser_login!

      set_locale(locale)

      hotel_attributes = hotel_attributes_from_params_for(:create)
      @hotel = Hotel.new(hotel_attributes)
      if @hotel.save
        flash[:success] = t('flash.resources.hotels.create.success')
        redirect fixed_url_with_locale("/org/hotels/#{ @hotel.id }", locale)
      else
        flash.now[:error] = t('flash.resources.hotels.create.failure')
        haml :"/pages/org/hotels/new_one.html"
      end
    end
  end

  # PUT requests
  # ------------

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    put "/#{ l }org/participants/:id" do |id|
      require_organiser_login!

      set_locale(locale)

      @participant = Participant.find(id)
      case params[:button]
      when 'approve'
        @participant.approve!
        @participant.save!
        redirect_to_url = "/#{ locale }/org/participants\#participant_#{ @participant.id }"
        redirect fixed_url(redirect_to_url)
      when 'disapprove'
        @participant.disapprove!
        @participant.save!
        redirect_to_url = "/#{ locale }/org/participants\#participant_#{ @participant.id }"
        redirect fixed_url(redirect_to_url)
      when 'update'
        require_main_organiser_login!

        participant_attributes =
          participant_attributes_from_params_for(:update)

        redirect_to_url = "/#{ locale }/org/participants/#{ @participant.id }"

        if @participant.update_attributes(participant_attributes)
          flash[:success] = t('flash.resources.participants.update.success')
          redirect fixed_url(redirect_to_url)
        else
          set_page(:"org/participants")

          flash.now[:error] = t('flash.resources.participants.update.failure')
          @attribute_names   = PARTICIPANT_ATTRIBUTE_NAMES_FOR[:update]
          @association_names = [:participations, :talk_proposals]

          if @association_names.include?(:participations)
            @conferences = Conference.default_order
          end

          haml :"/pages/org/participants/edit_one.html"
        end
      end
    end

    put "/#{ l }org/talk_proposals/:id" do |id| # TODO: improve this
      require_main_organiser_login!

      set_locale(locale)

      @talk_proposal = TalkProposal.find(id)
      case params[:button]
      when 'accept'
        @talk_proposal.accept
      end
      @talk_proposal.save!
      redirect fixed_url_with_locale("/org/participants#participant_#{ @talk_proposal.participant.id }", locale)
    end

    put "/#{ l }org/talks/:id" do |id|
      require_main_organiser_login!

      set_locale(locale)

      @talk = Talk.find(id)
      talk_attributes = talk_attributes_from_params_for(:update)

      if @talk.update_attributes(talk_attributes)
        flash[:success] = t('flash.resources.talks.update.success')
        redirect fixed_url_with_locale("/org/talks/#{ @talk.id }", locale)
      else
        set_page(:"org/talks")

        flash.now[:error] = t('flash.resources.talks.update.failure')
        @attribute_names = TALK_ATTRIBUTE_NAMES_FOR[:update]

        haml :"/pages/org/talks/edit_one.html"
      end
    end

    put "/#{ l }org/hotels/:id" do |id|
      require_main_organiser_login!

      set_locale(locale)

      @hotel = Hotel.find(id)
      hotel_attributes = hotel_attributes_from_params_for(:update)

      if @hotel.update_attributes(hotel_attributes)
        flash[:success] = t('flash.resources.hotels.update.success')
        redirect fixed_url_with_locale("/org/hotels/#{ @hotel.id }", locale)
      else
        set_page(:"org/hotels")

        flash.now[:error] = t('flash.resources.hotels.update.failure')
        @attribute_names = HOTEL_ATTRIBUTE_NAMES_FOR[:update]

        haml :"/pages/org/hotels/edit_one.html"
      end
      redirect fixed_url_with_locale("/org/hotels/#{ @hotel.id }", locale)
    end
  end

  # DELETE requests
  # ---------------

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    delete "/#{ l }org/participants/:id" do |id|
      require_main_organiser_login!

      set_locale(locale)

      Participant.find(id).destroy
      redirect fixed_url_with_locale("/org/participants", locale)
    end

    delete "/#{ l }org/talks/:id" do |id|
      require_main_organiser_login!

      set_locale(locale)

      Talk.find(id).destroy
      redirect fixed_url_with_locale("/org/talks", locale)
    end

    delete "/#{ l }org/hotels/:id" do |id|
      require_main_organiser_login!

      set_locale(locale)

      Hotel.find(id).destroy
      redirect fixed_url_with_locale("/org/hotels", locale)
    end
  end

  # Private methods
  # ===============
  #
  private

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
        session[:return_to] = request.fullpath if request.get?
        redirect fixed_url("/org/login")
      end
    end

    def require_main_organiser_login!
      unless main_organiser_logged_in?
        # halt [ 401, 'Not Authorized' ]
        flash[:error] = t('flash.filters.require_main_organiser_login')
        redirect fixed_url("/org/login")
      end
    end

    def participants_scope_from_filters(simple_filters)
      participants_filter   = simple_filters[:participants_filter]
      participations_filter = simple_filters[:participations_filter]

      participants_scope = if participants_filter.nil?
                             Participant.scoped
                           else
                             participants_filter.to_scope
                           end

      if participations_filter.nil?
        participants_scope
      else
        participants_scope.joins(:participations).
                           merge(participations_filter.to_scope).uniq
      end
    end

    def participants_filter_from_params(filter_values =
                                          params.key?('filter') && params['filter']['participants'])
      if filter_values
        filter_values = filter_values.reject{|_, v| v.empty? }

        filter = FriendlyRelationFilter.new(Participant)
        filter.filtering_attributes =
          [:last_name, :academic_position, :invitation_needed, :visa_needed]
        filter.set_filtering_values_from_text_hash(filter_values)
        filter
      end
    end

    def participations_filter_from_params(filter_values =
                                            params.key?('filter') && params['filter']['participations'])
      if filter_values
        filter_values = filter_values.reject{|_, v| v.empty? }

        filter = FriendlyRelationFilter.new(Participation)
        filter.filtering_attributes = [:conference_id, :approved]
        filter.set_filtering_values_from_text_hash(filter_values)
        filter
      end
    end

    def csv_from_collection(collection, attribute_procs, headers)
      CSV.generate(:col_sep  => ',',
                   :row_sep  => "\r\n",
                   :encoding => 'utf-8') do |csv|
        csv << headers << []
        collection.each do |object|
          csv << attribute_procs.map{|p| p[object] }
        end
      end
    end

end

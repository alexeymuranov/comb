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

  # Handlers
  # ========
  #
  ORG_PAGE_PREFIX = :'org/'

  ORGANISER_CONNEXION_PAGES =
    [ :participants_to_approve,
      :participants,
      :talks,
      :hotels,
      :utilities
    ].map { |p| :"#{ ORG_PAGE_PREFIX }#{ p }" }


  ORGANISER_CONNEXION_UTILITY_TABS = {
    :graduate_students_approved =>
      'email_lists/graduate_students/approved',
    :graduate_students_not_all_participations_approved =>
      'email_lists/graduate_students/not_all_participations_approved',
    :participants_with_talk_proposals =>
      'participants_with_talk_proposals',
    :talk_proposals_for_scientific_committee =>
      'talk_proposals_for_scientific_committee' }

  # Cache control
  before %r{/#{ ORG_PAGE_PREFIX }} do
    cache_control :no_cache
  end

  # GET requests
  # ------------

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    get "/#{ l }#{ ORG_PAGE_PREFIX }login" do
      set_locale(locale)
      set_page(:"#{ ORG_PAGE_PREFIX }login")
      haml :"/pages/#{ ORG_PAGE_PREFIX }login.html"
    end

    get "/#{ l }logout" do
      cache_control :no_cache
      log_out
      redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }login", locale)
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }" do
      require_organiser_login!

      redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }participants_to_approve", locale)
    end

    [ :"#{ ORG_PAGE_PREFIX }participants_to_approve",
      :"#{ ORG_PAGE_PREFIX }participants"
    ].each do |page|
      get "/#{ l }#{ page }" do
        require_organiser_login!

        set_locale(locale)
        set_page(page)

        @attributes = PARTICIPANT_ATTRIBUTES[:index]

        # Filtering
        filter_participants_for_index # TODO: find a better solution

        @filtering_by =
          [ [Participant,   :last_name],
            [Participation, :conference, {:name_proc => :identifier.to_proc}],
            [Participant,   :academic_position],
            [Participant,   :invitation_needed],
            [Participant,   :visa_needed],
            [Participation, :approved] ]

        if page == :"#{ ORG_PAGE_PREFIX }participants_to_approve"
          @filtering_by.delete([Participation, :approved])
          @filtered_participants =
            @filtered_participants.not_all_participations_approved
        end

        @filtered_participants = @filtered_participants.default_order

        @filtered_participants_count = @filtered_participants.count

        # Pagination
        @view_parameters = pagination_parameters_from_params
        per_page    = @view_parameters[:per_page]
        active_page = @view_parameters[:page]
        @participants =
          @filtered_participants.limit(per_page).offset(per_page * (active_page - 1))
        @view_parameters[:page_count] =
          ((@filtered_participants_count - 1) / per_page) + 1

        haml :"/pages/#{ ORG_PAGE_PREFIX }participants/index_all.html"
      end
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }participants/new" do
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"#{ ORG_PAGE_PREFIX }participants")

      @attributes   = PARTICIPANT_ATTRIBUTES[:create]
      @associations = [:participations]

      @participant = Participant.new

      if @associations.include?(:participations)
        @conferences = Conference.default_order
      end

      haml :"/pages/#{ ORG_PAGE_PREFIX }participants/new_one.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }participants/:id" do |id|
      require_organiser_login!

      set_locale(locale)
      # set_page(:#{ ORG_PAGE_PREFIX }participants)

      id = id.to_i

      @attributes = PARTICIPANT_ATTRIBUTES[:show]

      @participant = Participant.find(id)

      haml :"/pages/#{ ORG_PAGE_PREFIX }participants/show_one.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }participants/:id/edit" do |id|
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"#{ ORG_PAGE_PREFIX }participants")

      # @attributes = PARTICIPANT_ATTRIBUTES[:update]

      if only = params[:only]
        @attributes = []
        if only_attributes = only[:attributes]
          only_attributes = only_attributes.to_set
          PARTICIPANT_ATTRIBUTES[:update].each do |attr|
            @attributes << attr if only_attributes.include?(attr.to_s)
          end
        end

        @associations = []
        if only_associations = only[:associations]
          only_associations = only_associations.to_set
          if only_associations.include? 'participations'
            @associations << :participations
          end
        end
      else
        @attributes   = PARTICIPANT_ATTRIBUTES[:update]
        @associations = [:participations]
      end

      @participant = Participant.find(id)

      if @associations.include?(:participations)
        @conferences = Conference.default_order
      end

      haml :"/pages/#{ ORG_PAGE_PREFIX }participants/edit_one.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }participants/:id/delete" do |id|
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"#{ ORG_PAGE_PREFIX }participants")

      @participant = Participant.find(id)
      haml :"/pages/#{ ORG_PAGE_PREFIX }participants/delete_one.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }talks" do
      require_organiser_login!

      set_locale(locale)
      set_page(:"#{ ORG_PAGE_PREFIX }talks")

      @attributes = TALK_ATTRIBUTES[:index]
      @talks = Talk.default_order.all
      haml :"/pages/#{ ORG_PAGE_PREFIX }talks/index_all.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }talks/new" do
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:#{ ORG_PAGE_PREFIX }talks)

      @attributes = TALK_ATTRIBUTES[:create]

      @talk = Talk.new

      haml :"/pages/#{ ORG_PAGE_PREFIX }talks/new_one.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }talks/:id" do |id|
      require_organiser_login!

      set_locale(locale)
      # set_page(:#{ ORG_PAGE_PREFIX }talks)

      id = id.to_i

      @attributes = TALK_ATTRIBUTES[:show]

      @talk = Talk.find(id)

      haml :"/pages/#{ ORG_PAGE_PREFIX }talks/show_one.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }talks/:id/edit" do |id|
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"#{ ORG_PAGE_PREFIX }talks")

      @attributes = TALK_ATTRIBUTES[:update]
      @talk = Talk.find(id)
      haml :"/pages/#{ ORG_PAGE_PREFIX }talks/edit_one.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }talks/:id/delete" do |id|
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"#{ ORG_PAGE_PREFIX }talks")

      @talk = Talk.find(id)
      haml :"/pages/#{ ORG_PAGE_PREFIX }talks/delete_one.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }hotels" do
      require_organiser_login!

      set_locale(locale)
      set_page(:"#{ ORG_PAGE_PREFIX }hotels")

      @attributes = HOTEL_ATTRIBUTES[:index]
      @hotels = Hotel.default_order.all
      haml :"/pages/#{ ORG_PAGE_PREFIX }hotels/index_all.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }hotels/new" do
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:#{ ORG_PAGE_PREFIX }hotels)

      @attributes = HOTEL_ATTRIBUTES[:create]

      @hotel = Hotel.new

      haml :"/pages/#{ ORG_PAGE_PREFIX }hotels/new_one.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }hotels/:id" do |id|
      require_organiser_login!

      set_locale(locale)
      # set_page(:#{ ORG_PAGE_PREFIX }hotels)

      id = id.to_i

      @attributes = HOTEL_ATTRIBUTES[:show]

      @hotel = Hotel.find(id)

      haml :"/pages/#{ ORG_PAGE_PREFIX }hotels/show_one.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }hotels/:id/edit" do |id|
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"#{ ORG_PAGE_PREFIX }hotels")

      @attributes = HOTEL_ATTRIBUTES[:update]
      @hotel = Hotel.find(id)
      haml :"/pages/#{ ORG_PAGE_PREFIX }hotels/edit_one.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }hotels/:id/delete" do |id|
      require_main_organiser_login!

      set_locale(locale)
      # set_page(:"#{ ORG_PAGE_PREFIX }hotels")

      @hotel = Hotel.find(id)
      haml :"/pages/#{ ORG_PAGE_PREFIX }hotel/delete_one.html"
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }utilities" do
      require_organiser_login!

      set_locale(locale)
      set_page(:"#{ ORG_PAGE_PREFIX }utilities")

      haml :"/pages/#{ ORG_PAGE_PREFIX }utilities_layout" do nil end
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }utilities/email_lists/graduate_students/:status" do |status|
      require_organiser_login!

      set_locale(locale)
      set_page(:"#{ ORG_PAGE_PREFIX }utilities")

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

      haml :"/pages/#{ ORG_PAGE_PREFIX }utilities_layout" do
        haml :"/pages/#{ ORG_PAGE_PREFIX }participants/email_list",
             :layout => false
      end
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }utilities/participants_with_talk_proposals" do
      require_organiser_login!

      set_locale(locale)
      set_page(:"#{ ORG_PAGE_PREFIX }utilities")
      @utility_tab = :participants_with_talk_proposals

      @attributes = [:email]
      @participants = Participant.joins(:talk_proposals).uniq.default_order

      haml :"/pages/#{ ORG_PAGE_PREFIX }utilities_layout" do
        haml :"/pages/#{ ORG_PAGE_PREFIX }participants/participants_with_talk_proposals.html",
             :layout => false
      end
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }utilities/talk_proposals_for_scientific_committee" do
      require_organiser_login!

      set_locale(locale)
      set_page(:"#{ ORG_PAGE_PREFIX }utilities")
      @utility_tab = :talk_proposals_for_scientific_committee

      @participants_with_talk_proposals =
        Participant.joins(:talk_proposals).uniq.default_order

      haml :"/pages/#{ ORG_PAGE_PREFIX }utilities_layout" do
        haml :"/pages/#{ ORG_PAGE_PREFIX }utilities/talk_proposals_for_scientific_committee.html",
             :layout => false
      end
    end

    get "/#{ l }#{ ORG_PAGE_PREFIX }articles/talk_proposals_for_scientific_committee" do
      require_organiser_login!

      set_locale(locale)

      @participants_with_talk_proposals =
        Participant.joins(:talk_proposals).uniq.default_order

      haml :"/pages/#{ ORG_PAGE_PREFIX }articles/talk_proposals_for_scientific_committee.html",
           :layout => :simple_layout
    end
  end

  get "/login" do
    redirect fixed_url("/#{ ORG_PAGE_PREFIX }login")
  end

  get "/logout" do
    cache_control :no_cache
    log_out
    redirect fixed_url('/')
  end

  get "/download/participants.:format" do |format|
    require_organiser_login!

    filename =
      "filtered participants " +
      "#{ Time.now.strftime('%Y-%m-%d %k-%M') }.#{ format }"
    attachment filename

    @attributes =
      [ :last_name, :first_name, :email, :affiliation, :academic_position,
        :country, :city, :post_code, :street_address, :phone,
        :i_m_t_member, :g_d_r_member,
        :invitation_needed, :visa_needed, :special_requests ]
    @attribute_procs = []
    @headers = {}
    @attributes.each do |attr|
      attr_proc = attr.to_proc
      @attribute_procs << attr_proc
      @headers[attr_proc] =
        capitalize_first_letter_of(Participant.human_attribute_name(attr))
    end

    @conferences = Conference.default_order.all

    @conferences.each do |conf|
      participation_status = lambda { |participant|
        participation =
          participant.participations.find { |p| p.conference == conf }
        if participation
          "(#{ participation.approved? ? '✓' : '—' }) " +
            "[#{ participation.arrival_date } .. #{ participation.departure_date }]"
        end
      }
      @attribute_procs << participation_status
      @headers[participation_status] = conf.identifier

      committee_comments = lambda { |participant|
        participation =
          participant.participations.find { |p| p.conference == conf }
        if participation
          participation.committee_comments
        end
      }
      @attribute_procs << committee_comments
      @headers[committee_comments] =
        capitalize_first_letter_of(
          Participation.human_attribute_name(:committee_comments)) +
          " (#{ conf.identifier })"
    end

    filter_participants_for_download # TODO: find a better solution

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
    post "/#{ l }#{ ORG_PAGE_PREFIX }participants/" do
      require_main_organiser_login!

      set_locale(locale)

      participant_attributes =
        participant_attributes_from_params_for(:create)

      @participant = Participant.new(participant_attributes)

      if @participant.save
        flash[:success] = t('flash.resources.participants.create.success')
        redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }participants/#{ @participant.id }", locale)
      else
        set_page(:"#{ ORG_PAGE_PREFIX }participants")

        flash.now[:error] = t('flash.resources.participants.update.failure')
        @attributes = PARTICIPANT_ATTRIBUTES[:create]
        @associations = [:participations]

        if @associations.include?(:participations)
          @conferences = Conference.default_order
        end

        haml :"/pages/#{ ORG_PAGE_PREFIX }participants/new_one.html"
      end
    end

    post "/#{ l }#{ ORG_PAGE_PREFIX }login" do
      user = User.find_by_username(params[:username])
      if user && user.accept_password?(params[:password])
        log_in(user)
        if session.key?(:return_to)
          redirect fixed_url(session[:return_to])
          session.delete(:return_to)
        else
          redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }", locale)
        end
      else
        flash[:error] = t('flash.sessions.log_in.failure')
        redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }login", locale)
      end
    end

    post "/#{ l }#{ ORG_PAGE_PREFIX }talks/" do
      require_main_organiser_login!

      talk_attributes = talk_attributes_from_params_for(:create)
      case talk_attributes[:type]
      when 'ParallelTalk'
        @talk = ParallelTalk.new(talk_attributes)
      when 'PlenaryTalk'
        @talk = PlenaryTalk.new(talk_attributes)
      else
        @talk = Talk.new(talk_attributes)
      end

      @talk.conference_participation =
        Participation.where(params[:participation]).first

      if @talk.save
        flash[:success] = t('flash.resources.talks.create.success')
        redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }talks/#{ @talk.id }", locale)
      else
        flash.now[:error] = t('flash.resources.talks.create.failure')
        haml :"/pages/#{ ORG_PAGE_PREFIX }talks/new_one.html"
      end
    end

    post "/#{ l }#{ ORG_PAGE_PREFIX }hotels/" do
      require_main_organiser_login!

      hotel_attributes = hotel_attributes_from_params_for(:create)
      @hotel = Hotel.new(hotel_attributes)
      if @hotel.save
        flash[:success] = t('flash.resources.hotels.create.success')
        redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }hotels/#{ @hotel.id }", locale)
      else
        flash.now[:error] = t('flash.resources.hotels.create.failure')
        haml :"/pages/#{ ORG_PAGE_PREFIX }hotels/new_one.html"
      end
    end
  end

  # PUT requests
  # ------------

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    put "/#{ l }#{ ORG_PAGE_PREFIX }participants/:id" do |id|
      require_organiser_login!

      set_locale(locale)

      @participant = Participant.find(id)
      case params[:button]
      when 'approve'
        @participant.approve!
        @participant.save!
        redirect_to_url = "/#{ locale }/#{ ORG_PAGE_PREFIX }participants\#participant_#{ @participant.id }"
        redirect fixed_url(redirect_to_url)
      when 'disapprove'
        @participant.disapprove!
        @participant.save!
        redirect_to_url = "/#{ locale }/#{ ORG_PAGE_PREFIX }participants\#participant_#{ @participant.id }"
        redirect fixed_url(redirect_to_url)
      when 'update'
        require_main_organiser_login!

        participant_attributes =
          participant_attributes_from_params_for(:update)

        redirect_to_url = "/#{ locale }/#{ ORG_PAGE_PREFIX }participants/#{ @participant.id }"

        if @participant.update_attributes(participant_attributes)
          flash[:success] = t('flash.resources.participants.update.success')
          redirect fixed_url(redirect_to_url)
        else
          set_page(:"#{ ORG_PAGE_PREFIX }participants")

          flash.now[:error] = t('flash.resources.participants.update.failure')
          @attributes   = PARTICIPANT_ATTRIBUTES[:update]
          @associations = [:participations]

          if @associations.include?(:participations)
            @conferences = Conference.default_order
          end

          haml :"/pages/#{ ORG_PAGE_PREFIX }participants/edit_one.html"
        end
      end
    end

    put "/#{ l }#{ ORG_PAGE_PREFIX }talk_proposals/:id" do |id| # TODO: improve this
      require_main_organiser_login!

      @talk_proposal = TalkProposal.find(id)
      case params[:button]
      when 'accept'
        @talk_proposal.accept
      end
      @talk_proposal.save!
      redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }participants#participant_#{ @talk_proposal.participant.id }", locale)
    end

    put "/#{ l }#{ ORG_PAGE_PREFIX }talks/:id" do |id|
      require_main_organiser_login!

      set_locale(locale)

      @talk = Talk.find(id)
      talk_attributes = talk_attributes_from_params_for(:update)

      if @talk.update_attributes(talk_attributes)
        flash[:success] = t('flash.resources.talks.update.success')
        redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }talks/#{ @talk.id }", locale)
      else
        set_page(:"#{ ORG_PAGE_PREFIX }talks")

        flash.now[:error] = t('flash.resources.talks.update.failure')
        @attributes = TALK_ATTRIBUTES[:update]

        haml :"/pages/#{ ORG_PAGE_PREFIX }talks/edit_one.html"
      end
    end

    put "/#{ l }#{ ORG_PAGE_PREFIX }hotels/:id" do |id|
      require_main_organiser_login!

      set_locale(locale)

      @hotel = Hotel.find(id)
      hotel_attributes = hotel_attributes_from_params_for(:update)

      if @hotel.update_attributes(hotel_attributes)
        flash[:success] = t('flash.resources.hotels.update.success')
        redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }hotels/#{ @hotel.id }", locale)
      else
        set_page(:"#{ ORG_PAGE_PREFIX }hotels")

        flash.now[:error] = t('flash.resources.hotels.update.failure')
        @attributes = HOTEL_ATTRIBUTES[:update]

        haml :"/pages/#{ ORG_PAGE_PREFIX }hotels/edit_one.html"
      end
      redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }hotels/#{ @hotel.id }", locale)
    end
  end

  # DELETE requests
  # ---------------

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    delete "/#{ l }#{ ORG_PAGE_PREFIX }participants/:id" do |id|
      require_main_organiser_login!

      Participant.find(id).destroy
      redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }participants", locale)
    end

    delete "/#{ l }#{ ORG_PAGE_PREFIX }talks/:id" do |id|
      require_main_organiser_login!

      Talk.find(id).destroy
      redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }talks", locale)
    end

    delete "/#{ l }#{ ORG_PAGE_PREFIX }hotels/:id" do |id|
      require_main_organiser_login!

      Hotel.find(id).destroy
      redirect fixed_url_with_locale("/#{ ORG_PAGE_PREFIX }hotels", locale)
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

    # TODO: find a better solution. This method is used for its side-effects
    # which are not very well defined.
    def filter_participants_for_index
      @filtered_participants = Participant.scoped

      if filter_values = params['filter']
        @filtering_values = {}

        if participants_filter_values = filter_values['participants']
          participants_filter = FriendlyRelationFilter.new(Participant)
          participants_filter.filtering_attributes = @attributes
          participants_filter.set_filtering_values_from_text_hash(
            participants_filter_values)
          @filtered_participants =
            @filtered_participants.merge(participants_filter.to_scope)

          @filtering_values[Participant.table_name] =
            participants_filter.filtering_values_as_simple_nested_hash
        end

        if participations_filter_values = filter_values['participations']
          participations_filter =
            FriendlyRelationFilter.new(Participation)
          participations_filter.filtering_attributes =
            [:conference_id, :approved]
          participations_filter.set_filtering_values_from_text_hash(
            participations_filter_values)
          @filtered_participants =
            @filtered_participants.joins(:participations).
                                   merge(participations_filter.to_scope).uniq

          @filtering_values[Participation.table_name] =
            participations_filter.filtering_values_as_simple_nested_hash
        end
      end
    end

    # TODO: find a better solution. This method is used for its side-effects
    # which are not very well defined.
    def filter_participants_for_download
      @participants = Participant.scoped

      if filter_values = params['filter']
        if participants_filter_values = filter_values['participants']
          participants_filter = FriendlyRelationFilter.new(Participant)
          participants_filter.filtering_attributes = @attributes
          participants_filter.set_filtering_values_from_text_hash(
            participants_filter_values)
          @participants =
            @participants.merge(participants_filter.to_scope)
        end

        if participations_filter_values = filter_values['participations']
          participations_filter =
            FriendlyRelationFilter.new(Participation)
          participations_filter.filtering_attributes =
            [:conference_id, :approved]
          participations_filter.set_filtering_values_from_text_hash(
            participations_filter_values)
          @participants =
            @participants.joins(:participations).
                          merge(participations_filter.to_scope).uniq
        end
      end
    end

    def csv_from_collection(collection, attribute_procs, headers)
      CSV.generate(:col_sep  => ',',
                   :row_sep  => "\r\n",
                   :encoding => 'utf-8') do |csv|
        csv << attribute_procs.map { |p| headers[p] } << []
        collection.each do |object|
          csv << attribute_procs.map { |p| p[object] }
        end
      end
    end

end

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

  ORGANISER_CONNEXION_PAGES = [ :participants_to_approve,
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
      'participants_with_talk_proposals' }

  # Cache control
  before %r{/#{ ORG_PAGE_PREFIX }} do
    cache_control :no_cache
  end

  # GET requests
  # ------------

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }login" do
      set_locale(locale)
      set_page(:"#{ ORG_PAGE_PREFIX }login")
      haml :"/pages/#{ ORG_PAGE_PREFIX }login.html"
    end

    get "#{ REQUEST_BASE_URL }#{ l }logout" do
      cache_control :no_cache
      log_out
      redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }login")
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

        if participants_filter_values = params[:filter]
          participants_filter = FriendlyRelationFilter.new(Participant)
          participants_filter.filtering_attributes = @attributes
          participants_filter.set_filtering_values_from_text_hash(
            participants_filter_values)
          @participants = @participants.merge(participants_filter.to_scope)

          @filtering_values =
            participants_filter.filtering_attributes_as_simple_nested_hash

          participations_filter_values =
            participants_filter_values[:participations_attributes_exist]

          if participations_filter_values
            participations_filter =
              FriendlyRelationFilter.new(Participation)
            participations_filter.filtering_attributes =
              [:conference_id, :approved]
            participations_filter.set_filtering_values_from_text_hash(
              participations_filter_values)
            @participants =
              @participants.joins(:participations).
                            merge(participations_filter.to_scope).uniq

            @filtering_values['participations_attributes_exist'] =
              participations_filter.filtering_attributes_as_simple_nested_hash

          end
        end

        @filtering_parameters =
          [ :last_name,
            [:participations, :conference, { :name_attribute => :identifier }],
            :invitation_needed, :visa_needed,
            [:participations, :approved] ]

        if page == :"#{ ORG_PAGE_PREFIX }participants_to_approve"
          @filtering_parameters.delete([:participations, :approved])
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

    get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }utilities" do
      require_organiser_login!
      set_locale(locale)
      set_page(:"#{ ORG_PAGE_PREFIX }utilities")
      render :haml, :"/pages/#{ ORG_PAGE_PREFIX }utilities_layout" do nil end
    end

    get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }utilities/email_lists/graduate_students/:status" do |status|
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

      render :haml, :"/pages/#{ ORG_PAGE_PREFIX }utilities_layout" do
        haml :"/pages/#{ ORG_PAGE_PREFIX }participants/email_list",
             :layout => false
      end
    end

    get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }utilities/participants_with_talk_proposals" do
      require_organiser_login!
      set_locale(locale)
      set_page(:"#{ ORG_PAGE_PREFIX }utilities")

      @attributes = [:email]
      @participants = Participant.joins(:talk_proposals).uniq.default_order
      @utility_tab = :participants_with_talk_proposals

      render :haml, :"/pages/#{ ORG_PAGE_PREFIX }utilities_layout" do
        haml :"/pages/#{ ORG_PAGE_PREFIX }participants.html", :layout => false
      end
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

        @participant_to_edit = Participant.find(id)

        haml :"/pages/#{ ORG_PAGE_PREFIX }participants.html"
      end
    end

    get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }talks/edit/:id" do |id|
      require_main_organiser_login!
      set_locale(locale)
      set_page(:"#{ ORG_PAGE_PREFIX }talks")
      @attributes = TALK_ATTRIBUTES[:index]
      @talks = Talk.default_order.all
      @form_talk_id = id.to_i
      haml :"/pages/#{ ORG_PAGE_PREFIX }talks.html"
    end

    get "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }hotels/edit/:id" do |id|
      require_main_organiser_login!
      set_locale(locale)
      set_page(:"#{ ORG_PAGE_PREFIX }hotels")
      @attributes = HOTEL_ATTRIBUTES[:index]
      @hotels = Hotel.default_order.all
      @form_hotel_id = id.to_i
      haml :"/pages/#{ ORG_PAGE_PREFIX }hotels.html"
    end

    [ :"#{ ORG_PAGE_PREFIX }participants_to_approve",
      :"#{ ORG_PAGE_PREFIX }participants"
    ].each do |page|
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

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    post "#{ REQUEST_BASE_URL }#{ l }#{ ORG_PAGE_PREFIX }login" do
      user = User.find_by_username(params[:username])
      if user && user.accept_password?(params[:password])
        log_in(user)
        if session.key?(:return_to)
          redirect fixed_url(session[:return_to])
          session.delete(:return_to)
        else
          redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }")
        end
      else
        flash[:error] = t('flash.sessions.log_in.failure')
        redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }login")
      end
    end
  end

  # PUT requests
  # ------------

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    [:"#{ ORG_PAGE_PREFIX }participants_to_approve",
     :"#{ ORG_PAGE_PREFIX }participants"
    ].each do |page|
      put "#{ REQUEST_BASE_URL }#{ l }#{ page }/:id" do |id|
        require_organiser_login!
        @participant = Participant.find(id)
        case params[:button]
        when 'approve'
          @participant.approve!
        when 'disapprove'
          @participant.disapprove!
        when 'update'
          require_main_organiser_login!

          participant_attributes =
            participant_update_attributes_from_param_hash(
              params[:participant])

          @participant.update_attributes(participant_attributes)
          participations_attributes =
            participations_update_attributes_from_param_hash(
              params[:participations])
          participations_attributes.each do |attributes|
            participation = Participation.find(attributes[:id])
            if participation.participant_id = @participant.id
              participation.update_attributes(attributes)
              participation.save!
            end
          end
        end

        if @participant.save
          flash[:success] = t('flash.resources.participants.update.success')
          redirect fixed_url("/#{ locale }/#{ page }#participant_#{ @participant.id }")
        else
          set_locale(locale)
          set_page(page)

          flash.now[:error] = t('flash.resources.participants.update.failure')
          @attributes = PARTICIPANT_ATTRIBUTES[:index]

          @participants = Participant.scoped

          if page == :"#{ ORG_PAGE_PREFIX }participants_to_approve"
            @participants = @participants.not_all_participations_approved
          end

          @participants = @participants.default_order.all

          @participant_to_edit = @participant

          haml :"/pages/#{ ORG_PAGE_PREFIX }participants.html"
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
        talk_proposal_attributes.each_pair { |k, v|
          talk_proposal_attributes[k] = nil if v.empty?
        }
        @talk_proposal.update_attributes(talk_proposal_attributes)
      end
      @talk_proposal.save!
      redirect fixed_url("/#{ locale }/#{ ORG_PAGE_PREFIX }participants#participant_#{ @talk_proposal.participant.id }")
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

  # DELETE requests
  # ---------------

  LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
    [ :"#{ ORG_PAGE_PREFIX }participants_to_approve",
      :"#{ ORG_PAGE_PREFIX }participants"
    ].each do |page|
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

end

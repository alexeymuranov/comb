# encoding: UTF-8 (magic comment)

class CTT2013::Application < Sinatra::Base

  # == Authentication User model
  # ============================
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

  # = Route Handlers
  # ================
  #

  ORGANISER_CONNEXION_PAGES =
    [ 'participants',
      'plenary_talks',
      'parallel_talks',
      'hotels',
      'utilities'
    ].map{|p| "org/#{ p }" }


  ORGANISER_CONNEXION_UTILITY_TABS = {
    :talk_proposals_for_scientific_committee =>
      'talk_proposals_for_scientific_committee' }

  # == GET requests
  # ---------------

  # === Constants
  #

  # ==== Participants
  #
  PARTICIPANT_ATTRIBUTE_NAMES_FOR_INDEX =
    [:last_name, :first_name, :affiliation, :academic_position]

  PARTICIPANT_ATTRIBUTE_NAMES_FOR_SHOW =
    [ :first_name, :last_name, :email, :affiliation,
      :academic_position,
      :country, :city, :post_code, :street_address, :phone,
      :web_site,
      :i_m_t_member, :g_d_r_member,
      :invitation_needed, :visa_needed,
      :funding_requests,
      :special_requests,
      :approved ]

  PARTICIPANT_ATTRIBUTE_NAMES_FOR_DOWNLOAD =
    [ :last_name, :first_name, :email, :affiliation, :academic_position,
      :country, :city, :post_code, :street_address, :phone,
      :i_m_t_member, :g_d_r_member,
      :invitation_needed, :visa_needed, :special_requests ]

  # ==== Talks
  #
  TALK_ATTRIBUTE_NAMES_FOR_INDEX =
    [ :translated_type_name, :speaker_name, :title,
      :equipment,
      :date, :time, :room_or_auditorium ]

  TALK_ATTRIBUTE_NAMES_FOR_SHOW =
    [ :translated_type_name, :speaker_name, :title, :abstract,
      :equipment,
      :date, :time, :room_or_auditorium ]

  # ==== Hotels
  #
  HOTEL_ATTRIBUTE_NAMES_FOR_INDEX = [:name, :address, :phone, :web_site]

  HOTEL_ATTRIBUTE_NAMES_FOR_SHOW = [:name, :address, :phone, :web_site]

  get '/org/login' do
    set_page('org/login')
    haml :'/pages/org/login.html'
  end

  get '/login' do
    redirect fixed_url_with_locale('/org/login', locale)
  end

  get '/logout' do
    cache_control :no_cache
    log_out
    redirect fixed_url_with_locale('/org/login', locale)
  end

  get '/org/' do
    require_organiser_login!

    redirect fixed_url_with_locale('/org/participants', locale)
  end

  # ==== Participants
  #
  participant_attribute_procs_for_index =
    PARTICIPANT_ATTRIBUTE_NAMES_FOR_INDEX.map(&:to_proc)

  get '/org/participants' do
    require_organiser_login!

    set_page('org/participants')

    # Filtering
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

    # Custom ad hoc filtering
    @custom_filtering_parameters =
      custom_participant_filtering_parameters_from_params
    unless @custom_filtering_parameters.empty?
      filtered_participants = filtered_participants.merge(
        participants_scope_from_custom_filtering_parameters(
          @custom_filtering_parameters))
    end

    # Counting filtered
    @filtered_participants_count = filtered_participants.count

    # Sorting
    filtered_participants = filtered_participants.default_order

    # Pagination
    @view_parameters = view_parameters_from_params
    per_page     = @view_parameters[:per_page]
    current_page = @view_parameters[:page]
    @participants =
      filtered_participants.limit(per_page).
                            offset(per_page * (current_page - 1))
    @page_count = ((@filtered_participants_count - 1) / per_page) + 1

    # Page content
    @attribute_headers =
      PARTICIPANT_ATTRIBUTE_NAMES_FOR_INDEX.map { |attr|
        header_from_attribute_name(Participant, attr)
      }
    @attribute_procs = participant_attribute_procs_for_index

    @participations_header =
      header_from_attribute_name(Participant, :participations)

    @participation_procs = Conference.default_order.map { |conf|
      lambda { |participant|
        participation =
          participant.participations.find{|p| p.conference == conf }
        participation ? (participation.approved? ? '✓' : '—') : '·'
      }
    }

    haml :'/pages/org/participants/index_all.html'
  end

  get '/org/participants/new' do
    require_main_organiser_login!

    @participant = Participant.new

    render_new_participant_properly
  end

  get '/org/participants/:id' do |id|
    require_organiser_login!

    @attribute_names = PARTICIPANT_ATTRIBUTE_NAMES_FOR_SHOW

    @participant = Participant.find(id)

    haml :'/pages/org/participants/show_one.html'
  end

  get '/org/participants/:id/edit' do |id|
    require_main_organiser_login!

    @attribute_names   = participant_attribute_names_from_params_for_edit
    @association_names = participant_association_names_from_params_for_edit

    @participant = Participant.find(id)

    render_edit_participant_properly
  end

  get '/org/participants/:id/delete' do |id|
    require_main_organiser_login!

    @participant = Participant.find(id)

    haml :'/pages/org/participants/delete_one.html'
  end

  # ==== Talks
  #
  get '/org/plenary_talks' do
    require_organiser_login!

    set_page('org/plenary_talks')

    # Counting all
    @talks_count = PlenaryTalk.count

    # Filtering if needed
    filtered_talks = PlenaryTalk.scoped

    # Counting filtered
    @filtered_talks_count = filtered_talks.count

    # Sorting
    filtered_talks = filtered_talks.default_order

    # Setting view options
    @view_parameters = view_parameters_from_params

    # Pagination if needed
    @talks = filtered_talks

    haml :'/pages/org/talks/index_all.html'
  end

  get '/org/parallel_talks' do
    require_organiser_login!

    set_page('org/parallel_talks')

    # Counting all
    @talks_count = ParallelTalk.count

    # Filtering if needed
    filtered_talks = ParallelTalk.scoped

    # Counting filtered
    @filtered_talks_count = filtered_talks.count

    # Sorting
    filtered_talks = filtered_talks.default_order

    # Setting view options
    @view_parameters = view_parameters_from_params

    # Pagination if needed
    @talks = filtered_talks

    haml :'/pages/org/talks/index_all.html'
  end

  get '/org/talks/new' do
    require_main_organiser_login!

    @talk = Talk.new

    render_new_talk_properly
  end

  get '/org/talks/:id' do |id|
    require_organiser_login!

    @attribute_names = TALK_ATTRIBUTE_NAMES_FOR_SHOW

    @talk = Talk.find(id)

    haml :'/pages/org/talks/show_one.html'
  end

  get '/org/talks/:id/edit' do |id|
    require_main_organiser_login!

    @talk = Talk.find(id)

    render_edit_talk_properly
  end

  get '/org/talks/:id/delete' do |id|
    require_main_organiser_login!

    @talk = Talk.find(id)

    haml :'/pages/org/talks/delete_one.html'
  end

  # ==== Hotels
  #
  get '/org/hotels' do
    require_organiser_login!

    set_page('org/hotels')

    @hotels = Hotel.default_order

    haml :'/pages/org/hotels/index_all.html'
  end

  get '/org/hotels/new' do
    require_main_organiser_login!

    @hotel = Hotel.new

    render_new_hotel_properly
  end

  get '/org/hotels/:id' do |id|
    require_organiser_login!

    @attribute_names = HOTEL_ATTRIBUTE_NAMES_FOR_SHOW

    @hotel = Hotel.find(id)

    haml :'/pages/org/hotels/show_one.html'
  end

  get '/org/hotels/:id/edit' do |id|
    require_main_organiser_login!

    @hotel = Hotel.find(id)

    render_edit_hotel_properly
  end

  get '/org/hotels/:id/delete' do |id|
    require_main_organiser_login!

    @hotel = Hotel.find(id)

    haml :'/pages/org/hotels/delete_one.html'
  end

  # ==== Accommodations
  #
  get '/org/participants/:participant_id/accommodations/new' do |participant_id|
    require_main_organiser_login!

    @participant = Participant.find(participant_id)

    if @participant.nil?
      not_found
    end

    @accommodation =
      Accommodation.new(:participant    => @participant,
                        :arrival_date   => @participant.first_arrival_date,
                        :departure_date => @participant.last_departure_date)

    haml :'/pages/org/accommodations/new_one.html'
  end

  get '/org/participants/:participant_id/accommodations/edit' do |participant_id|
    require_main_organiser_login!

    @participant = Participant.find(participant_id)

    if @participant.nil?
      not_found
    end

    @accommodations = @participant.accommodations

    haml :'/pages/org/accommodations/edit_all.html'
  end

  # ==== Other
  #
  get '/org/utilities' do
    require_organiser_login!

    set_page('org/utilities')

    haml :'/pages/org/utilities_layout' do nil end
  end

  # get '/org/utilities/email_lists/speakers/:talk_type' do |talk_type|
  #   require_organiser_login!

  #   set_page('org/utilities')

  #   @participants = Participant.default_order

  #   case talk_type
  #   when 'plenary'
  #     @utility_tab = :plenary_speakers
  #     @participants =
  #       @participants.joins(:talks).merge(PlenaryTalk.scoped).uniq
  #   when 'parallel'
  #     @utility_tab = :parallel_speakers
  #     @participants =
  #       @participants.joins(:talks).merge(ParallelTalk.scoped).uniq
  #   end

  #   haml :'/pages/org/utilities_layout' do
  #     haml :'/pages/org/participants/email_list',
  #          :layout => false
  #   end
  # end

  get '/org/utilities/talk_proposals_for_scientific_committee' do
    require_organiser_login!

    set_page('org/utilities')
    @utility_tab = :talk_proposals_for_scientific_committee

    @participants_with_talk_proposals =
      Participant.joins(:talk_proposals).uniq.default_order

    haml :'/pages/org/utilities_layout' do
      haml :'/pages/org/utilities/talk_proposals_for_scientific_committee.html',
           :layout => false
    end
  end

  get '/org/articles/talk_proposals_for_scientific_committee' do
    require_organiser_login!

    @participants_with_talk_proposals =
      Participant.joins(:talk_proposals).uniq.default_order

    haml :'/pages/org/articles/talk_proposals_for_scientific_committee.html',
         :layout => :simple_layout
  end

  # ==== Participants
  #
  participant_attribute_procs_for_download =
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

  get '/download/participants.:format' do |format|
    require_organiser_login!

    attachment 'filtered participants ' +
               "#{ Time.now.strftime('%Y-%m-%d %k-%M') }.#{ format }"

    @headers =
      PARTICIPANT_ATTRIBUTE_NAMES_FOR_DOWNLOAD.map { |attr|
        header_from_attribute_name(Participant, attr)
      }
    @attribute_procs = participant_attribute_procs_for_download

    all_conferences = Conference.default_order.all

    @headers += all_conferences.map { |conf|
      [ conf.identifier,
        header_from_attribute_name(Participation, :committee_comments) +
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

    # Custom ad hoc filtering
    @participants =
      @participants.merge(participants_scope_from_custom_filtering_parameters)

    @participants = @participants.default_order

    case format
    when 'csv'
      content_type 'text/csv', :charset => 'utf-8'
      csv_from_collection(@participants, @attribute_procs, @headers)
    end
  end

  # == POST requests
  # ----------------

  post '/org/login' do
    user = User.find_by_username(params[:username])
    if user && user.accept_password?(params[:password])
      log_in(user)
      if session.key?(:return_to)
        redirect fixed_url(session[:return_to])
        session.delete(:return_to)
      else
        redirect fixed_url_with_locale('/org/participants', locale)
      end
    else
      flash[:error] = t('flash.sessions.log_in.failure')
      redirect fixed_url_with_locale('/org/login', locale)
    end
  end

  # ==== Participants
  #
  post '/org/participants/' do
    require_main_organiser_login!

    participant_attributes =
      participant_attributes_from_params_for(:create)

    @participant = Participant.new(participant_attributes)

    if @participant.save
      flash[:success] = t('flash.resources.participants.create.success')
      redirect fixed_url_with_locale("/org/participants/#{ @participant.id }", locale)
    else
      flash.now[:error] = t('flash.resources.participants.create.failure')
      render_new_participant_properly
    end
  end

  # ==== Talks
  #
  post '/org/talks/' do
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
      render_new_talk_properly
    end
  end

  # ==== Hotels
  #
  post '/org/hotels/' do
    require_main_organiser_login!

    hotel_attributes = hotel_attributes_from_params_for(:create)
    @hotel = Hotel.new(hotel_attributes)
    if @hotel.save
      flash[:success] = t('flash.resources.hotels.create.success')
      redirect fixed_url_with_locale("/org/hotels/#{ @hotel.id }", locale)
    else
      flash.now[:error] = t('flash.resources.hotels.create.failure')
      render_new_hotel_properly
    end
  end

  # ==== Accommodations
  #
  post '/org/participants/:participant_id/accommodations/' do |participant_id|
    require_main_organiser_login!

    @participant = Participant.find(participant_id)

    if @participant.nil?
      not_found
    end

    accommodation_attributes =
      participant_accommodation_attributes_from_params_for_create
    @accommodation = Accommodation.new(accommodation_attributes)
    @accommodation.participant = @participant

    if @accommodation.save
      flash[:success] = t('flash.resources.accommodations.create.success')
      redirect fixed_url_with_locale("/org/participants/#{ @participant.id }#accommodations", locale)
    else
      flash.now[:error] = t('flash.resources.accommodations.create.failure')
      haml :'/pages/org/accommodations/new_one.html'
    end
  end

  # == PUT requests
  # ---------------


  # ==== Participants
  #
  put '/org/participants/:id' do |id|
    require_organiser_login!

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
        flash.now[:error] = t('flash.resources.participants.update.failure')
        render_edit_participant_properly
      end
    end
  end

  # ==== Talk Proposals
  #
  put '/org/talk_proposals/:id' do |id| # TODO: improve this
    require_main_organiser_login!

    @talk_proposal = TalkProposal.find(id)
    case params[:button]
    when 'accept'
      @talk_proposal.accept
    end
    @talk_proposal.save!
    redirect fixed_url_with_locale("/org/participants/#{ @talk_proposal.participant.id }#talk_proposal", locale)
  end

  # ==== Talks
  #
  put '/org/talks/:id' do |id|
    require_main_organiser_login!

    @talk = Talk.find(id)
    talk_attributes = talk_attributes_from_params_for(:update)

    if @talk.update_attributes(talk_attributes)
      flash[:success] = t('flash.resources.talks.update.success')
      redirect fixed_url_with_locale("/org/talks/#{ @talk.id }", locale)
    else
      flash.now[:error] = t('flash.resources.talks.update.failure')
      render_edit_talk_properly
    end
  end

  # ==== Hotels
  #
  put '/org/hotels/:id' do |id|
    require_main_organiser_login!

    @hotel = Hotel.find(id)
    hotel_attributes = hotel_attributes_from_params_for(:update)

    if @hotel.update_attributes(hotel_attributes)
      flash[:success] = t('flash.resources.hotels.update.success')
      redirect fixed_url_with_locale("/org/hotels/#{ @hotel.id }", locale)
    else
      flash.now[:error] = t('flash.resources.hotels.update.failure')
      render_edit_hotel_properly
    end
  end

  # ==== Accommodations
  #
  put '/org/participants/:participant_id/accommodations/' do |participant_id|
    require_main_organiser_login!

    @participant = Participant.find(participant_id)

    if @participant.nil?
      not_found
    end

    accommodations_attributes =
      participant_accommodations_attributes_from_params_for_update_all

    if @participant.update_attributes(:accommodations_attributes => accommodations_attributes)
      flash[:success] = t('flash.resources.accommodations.update.success')
      redirect fixed_url_with_locale("/org/participants/#{ @participant.id }#accommodations", locale)
    else
      flash.now[:error] = t('flash.resources.accommodations.update.failure')
      @accommodations = @participant.accommodations
      haml :'/pages/org/accommodations/edit_all.html'
    end
  end

  # == DELETE requests
  # ------------------

  # ==== Participants
  #
  delete '/org/participants/:id' do |id|
    require_main_organiser_login!

    Participant.find(id).destroy
    redirect fixed_url_with_locale('/org/participants', locale)
  end

  # ==== Talks
  #
  delete '/org/talks/:id' do |id|
    require_main_organiser_login!

    @talk = Talk.find(id)
    @talk.destroy

    case @talk.type
    when 'PlenaryTalk'
      redirect fixed_url_with_locale('/org/plenary_talks', locale)
    when 'ParallelTalk'
      redirect fixed_url_with_locale('/org/parallel_talks', locale)
    else
      redirect fixed_url_with_locale('/org/', locale)
    end
  end

  # ==== Hotels
  #
  delete '/org/hotels/:id' do |id|
    require_main_organiser_login!

    Hotel.find(id).destroy
    redirect fixed_url_with_locale('/org/hotels', locale)
  end

  # ==== Accommodations
  #
  delete '/org/participants/:participant_id/accommodations/:id' do |participant_id, id|
    require_main_organiser_login!

    @participant = Participant.find(participant_id)
    @accommodation = @participant.accommodations.find(id)

    if @accommodation.nil?
      not_found
    end

    @accommodation.destroy

    redirect fixed_url_with_locale("/org/participant/#{ @participant.id }", locale)
  end

  # = Private methods
  # =================
  #
  private

    def log_in(user)
      session[:user_id] = user.id
    end

    def log_out
      session.clear
    end

    def current_user
      @current_user ||= User.find(session[:user_id].to_i)
    end

    def organiser_logged_in?
      if @organiser_logged_in.nil?
        user = current_user
        @organiser_logged_in =
          user && Set['organiser', 'main_organiser'].include?(user.role)
      else
        @organiser_logged_in
      end
    end

    def main_organiser_logged_in?
      if @main_organiser_logged_in.nil?
        @main_organiser_logged_in =
          organiser_logged_in? && current_user.role == 'main_organiser'
      else
        @main_organiser_logged_in
      end
    end

    def require_organiser_login!
      unless organiser_logged_in?
        # halt [ 401, 'Not Authorized' ]
        flash[:error] = t('flash.filters.require_organiser_login')
        session[:return_to] = request.fullpath if request.get?
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
          [ :last_name, :academic_position,
            :invitation_needed, :visa_needed, :i_m_t_member ]
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

    # Custom ad hoc filtering
    def participants_scope_from_custom_filtering_parameters(
          custom_filtering_parameters =
            custom_participant_filtering_parameters_from_params)
      participants_scope = Participant.scoped
      unless custom_filtering_parameters.empty?
        if custom_filtering_parameters[:participants_with_talk_proposals]
          participants_scope = participants_scope.joins(:talk_proposals).uniq
        end

        speaker_talk_types = custom_filtering_parameters[:speaker_talk_types]
        if speaker_talk_types
          participants_scope =
            participants_scope.joins(:talks).where('talks.type' => speaker_talk_types).uniq
        end

        participant_participations_count =
          @custom_filtering_parameters[:participant_participations_count]
        if participant_participations_count
          participants_scope =
            participants_scope.
              where('participants.id' =>
                      Participation.group(:participant_id).
                                    having('COUNT(id) = ?',
                                           participant_participations_count).
                                    select(:participant_id))
        end
      end
      participants_scope
    end

    def talks_scope_from_filters(simple_filters)
      talks_filter = simple_filters[:talks_filter]

      if talks_filter.nil?
        Talk.scoped
      else
        talks_filter.to_scope
      end
    end

    def talks_filter_from_params(filter_values =
                                   params.key?('filter') && params['filter']['talks'])
      if filter_values
        filter_values = filter_values.reject{|_, v| v.empty? }

        filter = FriendlyRelationFilter.new(Talk)
        filter.filtering_attributes = [:type]
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

    def render_new_participant_properly
      @attribute_names   ||= PARTICIPANT_ATTRIBUTE_NAMES_FOR[:create]
      @association_names ||= [:participations, :talk_proposals]

      if @association_names.include?(:participations)
        @conferences = Conference.default_order
      end

      haml :'/pages/org/participants/new_one.html'
    end

    def render_edit_participant_properly
      @attribute_names   ||= PARTICIPANT_ATTRIBUTE_NAMES_FOR[:update]
      @association_names ||= [:participations, :talk_proposals]

      if @association_names.include?(:participations)
        @conferences = Conference.default_order
      end

      haml :'/pages/org/participants/edit_one.html'
    end

    def render_new_talk_properly
      @attribute_names ||= TALK_ATTRIBUTE_NAMES_FOR[:create]

      haml :'/pages/org/talks/new_one.html'
    end

    def render_edit_talk_properly
      @attribute_names ||= TALK_ATTRIBUTE_NAMES_FOR[:update]

      haml :'/pages/org/talks/edit_one.html'
    end

    def render_new_hotel_properly
      @attribute_names ||= HOTEL_ATTRIBUTE_NAMES_FOR[:create]

      haml :'/pages/org/hotels/new_one.html'
    end

    def render_edit_hotel_properly
      @attribute_names ||= HOTEL_ATTRIBUTE_NAMES_FOR[:update]

      haml :'/pages/org/hotels/edit_one.html'
    end

end

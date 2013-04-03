# encoding: UTF-8 (magic comment)

class CTT2013 < Sinatra::Base

  # Models
  # ======
  #

  PARTICIPANT_ATTRIBUTES = {}
  PARTICIPANT_ATTRIBUTES[:registration] =
    [ :first_name, :last_name, :email,
      :affiliation, :academic_position,
      :country, :city, :post_code, :street_address, :phone,
      :i_m_t_member, :g_d_r_member,
      :invitation_needed, :visa_needed,
      # :funding_requests,
      :special_requests ]
  PARTICIPANT_ATTRIBUTES[:show] = PARTICIPANT_ATTRIBUTES[:index] =
    [ :first_name, :last_name, :email, :affiliation,
      :academic_position,
      :country, :city, :post_code, :street_address, :phone,
      :i_m_t_member, :g_d_r_member,
      :invitation_needed, :visa_needed,
      :funding_requests,
      :special_requests,
      :approved ]
  PARTICIPANT_ATTRIBUTES[:update] =
    [ :first_name, :last_name, :email, :affiliation,
      :academic_position,
      :country, :city, :post_code, :street_address, :phone,
      :i_m_t_member, :g_d_r_member,
      :invitation_needed, :visa_needed,
      :funding_requests,
      :special_requests ]

  TALK_ATTRIBUTES = {}
  TALK_ATTRIBUTES[:show] = TALK_ATTRIBUTES[:index] =
    [ :translated_type_name, :speaker_name, :title, :abstract,
      :date, :time, :room_or_auditorium ]
  TALK_ATTRIBUTES[:update] = TALK_ATTRIBUTES[:create] =
    [ :type, :participant_id, :title, :abstract,
      :date, :time, :room_or_auditorium ]

  HOTEL_ATTRIBUTES = {}
  HOTEL_ATTRIBUTES[:show] = HOTEL_ATTRIBUTES[:index] =
    [:name, :address, :phone, :web_site]
  HOTEL_ATTRIBUTES[:update] = HOTEL_ATTRIBUTES[:create] = HOTEL_ATTRIBUTES[:show]

  # Internationalisation
  # ====================
  #

  LOCALE_FROM_URL_LOCALE_FRAGMENT = {}.tap do |h|
    LOCALES.each do |locale|
      h["#{ locale }/"] = locale
    end
    h[''] = DEFAULT_LOCALE
  end

  private

    def pagination_parameters_from_params
      view_parameters = params[:view] || {}
      per_page    = (view_parameters[:per_page] || 10).to_i
      active_page = (view_parameters[:page]     || 1 ).to_i
      { :per_page   => per_page,
        :page       => active_page }
    end

    def conference_ids_from_params
      submitted_ids = params[:conference_ids]
      submitted_ids.is_a?(Array) ? submitted_ids.map(&:to_i) : []
    end

    def participant_attributes_from_params_for(action)
      submitted_attributes = params[:participant]
      attributes = {}

      PARTICIPANT_ATTRIBUTES[action].each do |attr|
        if submitted_attributes.key?(key = attr.to_s)
          value = submitted_attributes[key]
          attributes[attr] = value == '' ? nil : value
        end
      end

      attributes[:participations_attributes] =
        participant_participations_attributes_from_params

      attributes
    end

    def participant_participations_attributes_from_params
      submitted_attributes = params[:participations]

      {}.tap do |participations_attributes|
        submitted_attributes.each_pair do |key, attributes|
          participations_attributes[key] = {}.tap do |h|
            [ :id, :conference_id,
              :arrival_date, :departure_date,
              :committee_comments,
              :_destroy
            ].each do |attr|
              if attributes.key?(key = attr.to_s)
                value = attributes[key]
                h[attr] = value == '' ? nil : value
              end
            end
          end
        end

        talk_proposals_attributes =
          participation_talk_proposals_attributes_from_params

        talk_proposals_attributes.each do |t_p_aa|
          participation_key = t_p_aa.delete(:_participation_key)
          if participations_attributes.key?(participation_key)
            participations_attributes[participation_key][:talk_proposal_attributes] = t_p_aa
          end
        end
      end.values
    end

    def participation_talk_proposals_attributes_from_params
      submitted_attributes = params[:talk_proposals]

      {}.tap do |talk_proposals_attributes|
        submitted_attributes.each_pair do |key, attributes|
          talk_proposals_attributes[key] = {}.tap do |h|
            [ :id, :participation_id,
              :title, :abstract,
              :_destroy, :_participation_key
            ].each do |attr|
              if attributes.key?(key = attr.to_s)
                value = attributes[key]
                h[attr] = value == '' ? nil : value
              end
            end

            if [:title, :abstract].all? { |a| h[a].nil? }
              h[:_destroy] = true
            end
          end
        end
      end.values
    end

    def talk_attributes_from_params_for(action)
      submitted_attributes = params[:talk]
      attributes = {}

      TALK_ATTRIBUTES[action].each do |attr|
        if submitted_attributes.key?(key = attr.to_s)
          value = submitted_attributes[key]
          attributes[attr] = value == '' ? nil : value
        end
      end

      attributes
    end

    def hotel_attributes_from_params_for(action)
      submitted_attributes = params[:hotel]
      attributes = {}

      HOTEL_ATTRIBUTES[action].each do |attr|
        if submitted_attributes.key?(key = attr.to_s)
          value = submitted_attributes[key]
          attributes[attr] = value == '' ? nil : value
        end
      end

      attributes
    end

end

require_relative 'public'
require_relative 'organiser_connexion'

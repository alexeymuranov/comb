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
  PARTICIPANT_ATTRIBUTES[:update] = PARTICIPANT_ATTRIBUTES[:show]

  TALK_ATTRIBUTES = {}
  TALK_ATTRIBUTES[:show] = TALK_ATTRIBUTES[:index] =
    [ :translated_type_name, :speaker_name, :title, :abstract,
      :date, :time, :room_or_auditorium ]

  HOTEL_ATTRIBUTES = {}
  HOTEL_ATTRIBUTES[:show] = HOTEL_ATTRIBUTES[:index] =
    [:name, :address, :phone, :web_site]

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

    def participant_attributes_from_params_for(action)
      submitted_atributes = params[:participant]
      participant_attributes = {}

      PARTICIPANT_ATTRIBUTES[action].each do |attr|
        value = submitted_atributes[attr.to_s]
        participant_attributes[attr] = value unless value.nil? || value.empty?
      end

      participant_attributes[:participations_attributes] =
        participant_participations_attributes_from_params

      participant_attributes
    end

    def participant_participations_attributes_from_params
      submitted_atributes = params[:participations]

      {}.tap do |participations_attributes|
        submitted_atributes.each_pair do |key, attributes|
          participations_attributes[key] = {}.tap do |h|

            [ :id, :conference_id,
              :arrival_date, :departure_date,
              :committee_comments,
              :_destroy
            ].each do |attr|
              value = attributes[attr.to_s]
              h[attr] = value unless value.nil? || value.empty?
            end
          end
        end

        talk_proposals_attributes =
          participation_talk_proposals_attributes_from_params

        talk_proposals_attributes.each do |t_p_aa|
          participations_attributes[t_p_aa.delete(:_participation_key)] \
                                   [:talk_proposal_attributes] = t_p_aa
        end
      end.values
    end

    def participation_talk_proposals_attributes_from_params
      submitted_atributes = params[:talk_proposals]

      {}.tap do |talk_proposals_attributes|
        submitted_atributes.each_pair do |key, attributes|
          talk_proposals_attributes[key] = {}.tap do |h|
            [ :id, :participation_id,
              :title, :abstract,
              :_destroy, :_participation_key
            ].each do |attr|
              value = attributes[attr.to_s]
              h[attr] = value unless value.nil? || value.empty?
            end

            unless [:title, :abstract].any? { |a| h.key?(a) }
              h[:_destroy] = true
            end
          end
        end
      end.values
    end

end

require_relative 'public'
require_relative 'organiser_connexion'

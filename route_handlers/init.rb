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

end

require_relative 'public'
require_relative 'organiser_connexion'

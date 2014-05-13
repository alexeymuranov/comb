# encoding: UTF-8 (magic comment)

class CTT2013::Application

  # Pages
  # -----

  COMMON_HOME_PAGE = 'common/index.php'

  COMB_PAGE_PREFIX = 'ldtg-mb/'

  PUBLIC_PAGES =
    [ 'index',
      'program',
      'scientific_committee',
      'organising_committee',
      'directions_to_get_here',
      'funding',
      'contacts',
      'accommodation',
      'participants',
      'registration', # only displays that registration is closed
      'useful_links'
    ].map{|p| "#{ COMB_PAGE_PREFIX }#{ p }" }

  STATIC_PUBLIC_PAGES =
    Set[ 'index',
         'program',
         'scientific_committee',
         'organising_committee',
         'directions_to_get_here',
         'funding',
         'contacts',
         'registration',
         'useful_links'
       ].map{|p| "#{ COMB_PAGE_PREFIX }#{ p }" }

  COMB_HOME_PAGE = PUBLIC_PAGES[0]
  PAGE_URL_FRAGMENTS = PUBLIC_PAGES.reduce({}){|h, p| h[p] = [p.to_s]; h }
  PAGE_URL_FRAGMENTS[COMB_HOME_PAGE] << COMB_PAGE_PREFIX

  # Model attributes
  # ----------------

  PARTICIPANT_ATTRIBUTE_NAMES_FOR = {}
  PARTICIPANT_ATTRIBUTE_NAMES_FOR[:registration] =
    Set[ :first_name, :last_name, :email,
         :affiliation, :academic_position,
         :country, :city, :post_code, :street_address, :phone,
         :web_site,
         :i_m_t_member, :g_d_r_member,
         :invitation_needed, :visa_needed,
         # :funding_requests,
         :special_requests ]
  PARTICIPANT_ATTRIBUTE_NAMES_FOR[:create] =
    Set[ :first_name, :last_name, :email, :affiliation,
         :academic_position,
         :country, :city, :post_code, :street_address, :phone,
         :web_site,
         :i_m_t_member, :g_d_r_member,
         :invitation_needed, :visa_needed,
         :funding_requests,
         :special_requests ]
  PARTICIPANT_ATTRIBUTE_NAMES_FOR[:update] =
    PARTICIPANT_ATTRIBUTE_NAMES_FOR[:create]

  TALK_ATTRIBUTE_NAMES_FOR = {}
  TALK_ATTRIBUTE_NAMES_FOR[:create] =
    Set[ :type, :participant_id, :title, :abstract,
         :equipment,
         :date, :time, :room_or_auditorium ]
  TALK_ATTRIBUTE_NAMES_FOR[:update] =
    TALK_ATTRIBUTE_NAMES_FOR[:create]

  HOTEL_ATTRIBUTE_NAMES_FOR = {}
  HOTEL_ATTRIBUTE_NAMES_FOR[:create] =
    Set[:name, :address, :phone, :web_site]
  HOTEL_ATTRIBUTE_NAMES_FOR[:update] = HOTEL_ATTRIBUTE_NAMES_FOR[:create]

  PARTICIPANT_ACCOMMODATION_ATTRIBUTE_NAMES_FOR_CREATE =
    Set[ :hotel_id, :arrival_date, :departure_date ]
  PARTICIPANT_ACCOMMODATION_ATTRIBUTE_NAMES_FOR_UPDATE =
    Set[ :arrival_date, :departure_date ]

  # Internationalisation
  # --------------------

  LOCALE_FROM_URL_LOCALE_FRAGMENT = CTT2013::LOCALES.reduce({}) { |h, locale|
    h["#{ locale }/"] = locale
    h
  }
  # XXX: The assignment of the `DEFAULT_LOCALE` to `''` is not
  # completely consistent with the case of explicit locales.
  LOCALE_FROM_URL_LOCALE_FRAGMENT[''] = CTT2013::DEFAULT_LOCALE

end

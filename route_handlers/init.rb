# encoding: UTF-8 (magic comment)

class CTT2013 < Sinatra::Base

  # Models
  # ======
  #

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
  # ====================
  #

  LOCALE_FROM_URL_LOCALE_FRAGMENT = LOCALES.reduce({}) { |h, locale|
    h["#{ locale }/"] = locale
    h
  }
  # XXX: The assignment of the `DEFAULT_LOCALE` to `''` is not
  # completely consistent with the case of explicit locales.
  LOCALE_FROM_URL_LOCALE_FRAGMENT[''] = DEFAULT_LOCALE

  private

    def set_locale(locale)
      I18n.locale = @locale = locale
      @other_locales = LOCALES - [@locale]
    end

    def locale
      @locale || DEFAULT_LOCALE
    end

    def set_page(page)
      @page = page
      @base_title = t('base_co_m_b_page_title')
      @title =
        "#{ @base_title } | #{ t(:title, :scope => page_i18n_scope(@page)) }"
    end

    def page
      @page
    end

    # def locale_from_user_input(suggested_locale)
    #   suggested_locale = suggested_locale.to_s.downcase
    #   LOCALES.find{|l| l.to_s == suggested_locale } || DEFAULT_LOCALE
    # end

    # def page_from_user_input(suggested_page)
    #   suggested_page = suggested_page.to_s.downcase
    #   PUBLIC_PAGES.find{|p| p.to_s == suggested_page } || COMB_HOME_PAGE
    # end

end

require_relative 'params_processing'
require_relative 'filters'
require_relative 'public'
require_relative 'organiser_connexion'

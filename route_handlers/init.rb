# encoding: UTF-8 (magic comment)

class CTT2013 < Sinatra::Base

  # Models
  # ======
  #

  PARTICIPANT_ATTRIBUTES_FOR = {}
  PARTICIPANT_ATTRIBUTES_FOR[:registration] =
    [ :first_name, :last_name, :email,
      :affiliation, :academic_position,
      :country, :city, :post_code, :street_address, :phone,
      :i_m_t_member, :g_d_r_member,
      :invitation_needed, :visa_needed,
      # :funding_requests,
      :special_requests ]
  PARTICIPANT_ATTRIBUTES_FOR[:update] = PARTICIPANT_ATTRIBUTES_FOR[:create] =
    [ :first_name, :last_name, :email, :affiliation,
      :academic_position,
      :country, :city, :post_code, :street_address, :phone,
      :i_m_t_member, :g_d_r_member,
      :invitation_needed, :visa_needed,
      :funding_requests,
      :special_requests ]

  TALK_ATTRIBUTES_FOR = {}
  TALK_ATTRIBUTES_FOR[:update] = TALK_ATTRIBUTES_FOR[:create] =
    [ :type, :participant_id, :title, :abstract,
      :date, :time, :room_or_auditorium ]

  HOTEL_ATTRIBUTES_FOR = {}
  HOTEL_ATTRIBUTES_FOR[:update] = HOTEL_ATTRIBUTES_FOR[:create] =
    [:name, :address, :phone, :web_site]

  # Internationalisation
  # ====================
  #

  LOCALE_FROM_URL_LOCALE_FRAGMENT = LOCALES.reduce({}) { |h, locale|
    h["#{ locale }/"] = locale
    h
  }
  LOCALE_FROM_URL_LOCALE_FRAGMENT[''] = DEFAULT_LOCALE

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

    # def locale_from_user_input(suggested_locale)
    #   suggested_locale = suggested_locale.to_s.downcase
    #   LOCALES.find { |l| l.to_s == suggested_locale } || DEFAULT_LOCALE
    # end

    # def page_from_user_input(suggested_page)
    #   suggested_page = suggested_page.to_s.downcase
    #   PUBLIC_PAGES.find { |p| p.to_s == suggested_page } || COMB_HOME_PAGE
    # end

    def pagination_parameters_from_params
      view_parameters = params['view'] || {}
      per_page    = (view_parameters['per_page'] || 10).to_i
      active_page = (view_parameters['page']     || 1 ).to_i
      { :per_page   => per_page,
        :page       => active_page }
    end

    def conference_ids_from_params
      submitted_ids = params['conference_ids'] || []
      submitted_ids.map(&:to_i)
    end

    def participant_attributes_from_params_for(action)
      submitted_attributes = params['participant'] || {}

      PARTICIPANT_ATTRIBUTES_FOR[action].map { |attr|
        [attr, attr.to_s]
      }.select { |_, key|
        submitted_attributes.key?(key)
      }.map { |attr, key|
        [attr, submitted_attributes[key]]
      }.map { |attr, raw_value|
        [attr, (raw_value == '' ? nil : raw_value)]
      }.reduce({}) { |h, attr__value|
        attr, value = attr__value
        h[attr] = value
        h
      }.tap do |attributes|
        attributes[:participations_attributes] =
          participant_participations_attributes_from_params_for(action)
      end
    end

    def participant_participations_attributes_from_params_for(action)
      submitted_attributes =
        params['participations'] || Hash.new{|h, k| h[k] = {}}

      submitted_attributes.reduce({}) { |processed_attributes, raw_key__raw_attributes|
        raw_key, raw_attributes = raw_key__raw_attributes

        processed_attributes[raw_key] =
          [ :id, :conference_id,
            :arrival_date, :departure_date,
            :committee_comments,
            :_destroy
          ].map { |attr|
            [attr, attr.to_s]
          }.select { |_, subkey|
            raw_attributes.key?(subkey)
          }.map { |attr, subkey|
            [attr, raw_attributes[subkey]]
          }.map { |attr, raw_value|
            [attr, (raw_value == '' ? nil : raw_value)]
          }.reduce({}) { |h, attr__value|
            attr, value = attr__value
            h[attr] = value
            h
          }
        processed_attributes
      }.tap do |attributes|
        unless action == :registration
          participation_talk_proposals_attributes_from_params.each do |t_p_aa|
            participation_key = t_p_aa.delete(:_participation_key)
            if attributes.key?(participation_key)
               attributes[participation_key] \
                         [:talk_proposal_attributes] = t_p_aa
            end
          end
        end
      end.values
    end

    def participation_talk_proposals_attributes_from_params
      submitted_attributes =
        params['talk_proposals'] || Hash.new{|h, k| h[k] = {}}

      submitted_attributes.reduce({}) { |processed_attributes, raw_key__raw_attributes|
        raw_key, raw_attributes = raw_key__raw_attributes

        processed_attributes[raw_key] =
          [ :id, :participation_id,
            :title, :abstract,
            :_destroy, :_participation_key
          ].map { |attr|
            [attr, attr.to_s]
          }.select { |_, subkey|
            raw_attributes.key?(subkey)
          }.map { |attr, subkey|
            [attr, raw_attributes[subkey]]
          }.map { |attr, raw_value|
            [attr, (raw_value == '' ? nil : raw_value)]
          }.reduce({}) { |h, attr__value|
            attr, value = attr__value
            h[attr] = value
            h
          }.tap do |h|
            if [:title, :abstract].all? { |a| h[a].nil? }
              h[:_destroy] = true
            end
          end
        processed_attributes
      }.values
    end

    def talk_attributes_from_params_for(action)
      submitted_attributes = params['talk'] || {}

      TALK_ATTRIBUTES_FOR[action].map { |attr|
        [attr, attr.to_s]
      }.select { |_, key|
        submitted_attributes.key?(key)
      }.map { |attr, key|
        [attr, submitted_attributes[key]]
      }.map { |attr, raw_value|
        [attr, (raw_value == '' ? nil : raw_value)]
      }.reduce({}) { |h, attr__value|
        attr, value = attr__value
        h[attr] = value
        h
      }
    end

    def hotel_attributes_from_params_for(action)
      submitted_attributes = params['hotel'] || {}

      HOTEL_ATTRIBUTES_FOR[action].map { |attr|
        [attr, attr.to_s]
      }.select { |_, key|
        submitted_attributes.key?(key)
      }.map { |attr, key|
        [attr, submitted_attributes[key]]
      }.map { |attr, raw_value|
        [attr, (raw_value == '' ? nil : raw_value)]
      }.reduce({}) { |h, attr__value|
        attr, value = attr__value
        h[attr] = value
        h
      }
    end

end

require_relative 'filters'
require_relative 'public'
require_relative 'organiser_connexion'

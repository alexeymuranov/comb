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
  LOCALE_FROM_URL_LOCALE_FRAGMENT[''] = DEFAULT_LOCALE

  private

    def set_locale(locale)
      I18n.locale = @locale = locale
      @other_locales = LOCALES.reject{|l| l == @locale }
    end

    def set_page(page)
      @page = page
      @base_title = t('base_co_m_b_page_title')
      @title =
        "#{ @base_title } | #{ t(:title, :scope => page_i18n_scope(@page)) }"
    end

    # def locale_from_user_input(suggested_locale)
    #   suggested_locale = suggested_locale.to_s.downcase
    #   LOCALES.find{|l| l.to_s == suggested_locale } || DEFAULT_LOCALE
    # end

    # def page_from_user_input(suggested_page)
    #   suggested_page = suggested_page.to_s.downcase
    #   PUBLIC_PAGES.find{|p| p.to_s == suggested_page } || COMB_HOME_PAGE
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

      PARTICIPANT_ATTRIBUTE_NAMES_FOR[action].map { |attr|
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
            if [:title, :abstract].all?{|a| h[a].nil? }
              h[:_destroy] = true
            end
          end
        processed_attributes
      }.values
    end

    def talk_attributes_from_params_for(action)
      submitted_attributes = params['talk'] || {}

      TALK_ATTRIBUTE_NAMES_FOR[action].map { |attr|
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

    def talk_participation_attributes_from_params_for_create
      submitted_attributes = params['participation'] || {}

      [:participant_id, :conference_id].map { |attr|
        [attr, submitted_attributes[attr.to_s].to_i]
      }.reduce({}) { |h, attr__value|
        attr, value = attr__value
        h[attr] = value
        h
      }
    end

    def hotel_attributes_from_params_for(action)
      submitted_attributes = params['hotel'] || {}

      HOTEL_ATTRIBUTE_NAMES_FOR[action].map { |attr|
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

    def participant_accommodation_attributes_from_params_for_create
      submitted_attributes = params['accommodation'] || {}

      PARTICIPANT_ACCOMMODATION_ATTRIBUTE_NAMES_FOR_CREATE.map { |attr|
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

    def participant_accommodations_attributes_from_params_for_update_all
      submitted_attributes =
        params['accommodations'] || Hash.new{|h, k| h[k] = {}}

      submitted_attributes.reduce({}) { |processed_attributes, raw_key__raw_attributes|
        raw_key, raw_attributes = raw_key__raw_attributes

        processed_attributes[raw_key] =
          [ :id,
            *PARTICIPANT_ACCOMMODATION_ATTRIBUTE_NAMES_FOR_UPDATE,
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
      }.values
    end

    def participant_attribute_names_from_params_for_edit
      if only = params['only']
        case only_attributes = only['attributes']
        when Array
          only_attributes = only_attributes.to_set
          PARTICIPANT_ATTRIBUTE_NAMES_FOR[:update].select{ |n|
            only_attributes.include?(n.to_s)
          }
        when nil
          []
        else
          PARTICIPANT_ATTRIBUTE_NAMES_FOR[:update]
        end
      else
        PARTICIPANT_ATTRIBUTE_NAMES_FOR[:update]
      end
    end

    def participant_association_names_from_params_for_edit
      if only = params['only']
        case only_associations = only['associations']
        when Array
          only_associations = only_associations.to_set
          [:participations, :talk_proposals].select{ |n|
            only_associations.include?(n.to_s)
          }
        when nil
          []
        else
          [:participations, :talk_proposals]
        end
      else
        [:participations, :talk_proposals]
      end
    end

end

require_relative 'filters'
require_relative 'public'
require_relative 'organiser_connexion'

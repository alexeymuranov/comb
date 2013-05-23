# encoding: UTF-8 (magic comment)

class CTT2013
  private

    def view_parameters_from_params(submitted_view_parameters = params['view'])
      submitted_view_parameters ||= {}
      per_page    = (submitted_view_parameters['per_page'] || 10).to_i
      active_page = (submitted_view_parameters['page']     ||  1).to_i
      show_as     = submitted_view_parameters['show_as']
      { :per_page => per_page,
        :page     => active_page,
        :show_as  => show_as }
    end

    def custom_participant_filtering_parameters_from_params(submitted_filtering_parameters = params['custom_filter'])
      if submitted_filtering_parameters.nil?
        return {}
      end

      filtering_parameters = {}

      if submitted_filtering_parameters['participants_with_talk_proposals'] == '1'
        filtering_parameters[:participants_with_talk_proposals] = true
      end

      participant_participations_count =
        submitted_filtering_parameters['participant_participations_count']
      unless Set[nil, ''].include?(participant_participations_count)
        filtering_parameters[:participant_participations_count] =
          participant_participations_count.to_i
      end

      filtering_parameters
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

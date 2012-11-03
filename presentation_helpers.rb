# encoding: UTF-8 (magic comment)

require 'i18n' # Internationalisation

class CTT2013
  module PresentationHelpers
    module AbstractSmarterModelHelpers
      def attribute_in_description(object, attribute, hints = {})
        object_class = object.class

        unless column_type = hints[:column_type]
          # NOTE: assumes that `AttributeTypes` module is included
          column_type = object_class.attribute_type(attribute)
        end

        human_attribute_name =
          capitalize_first_letter_of(
            object_class.human_attribute_name(attribute))

        format_localisation_key =
          case column_type
          when :boolean
            'formats.attribute_name?'
          else
            'formats.attribute_name:'
          end

        name_html =
          t(format_localisation_key, :attribute => human_attribute_name)

        value = object.public_send(attribute)

        case column_type
        when :boolean
          html_class = :boolean
          value_html = value.nil? ? nil : text_from_boolean(value)
        when :date, :datetime
          html_class = column_type
          value_html = l value, :format => :custom
        when :time
          html_class = :time
          value_html = l value, :format => :time_of_the_day
        when :integer
          html_class = :number
          value_html = value
        else
          html_class = column_type
          value_html = value
        end

        readonly = object_class.readonly_attributes.include?(attribute.to_s)
        if readonly
          value_html =
            haml :'/helper_partials/abstract_smarter_model/_readonly_value_in_description',
                 :locals => { :value => value_html }
        end

        haml :'/helper_partials/abstract_smarter_model/_attribute_in_description',
             :locals => { :name       => name_html,
                          :value      => value_html,
                          :html_class => html_class }
      end

      def singular_association_in_description(object, attr)
        fail # TODO: implement me
      end

      def collection_association_in_description(object, attr)
        fail # TODO: implement me
      end

      def description_list(object, attributes)
        fail # TODO: implement me
      end
    end

    include AbstractSmarterModelHelpers

    module ParticipantHelpers
    end

    include ParticipantHelpers
  end
end

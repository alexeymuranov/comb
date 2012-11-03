# encoding: UTF-8 (magic comment)

require 'i18n' # Internationalisation

class CTT2013
  module PresentationHelpers
    module AbstractSmarterModelHelpers
      def attribute_name_as_label(model, attribute, column_type = nil)
        # NOTE: it is assumed that `AttributeTypes` module is included
        column_type ||= model.attribute_type(attribute)

        human_attribute_name =
          capitalize_first_letter_of(
            model.human_attribute_name(attribute))

        format_localisation_key =
          case column_type
          when :boolean
            'formats.attribute_name?'
          else
            'formats.attribute_name:'
          end

        t(format_localisation_key, :attribute => human_attribute_name)
      end

      def attribute_input_html_type(model, attribute, column_type = nil)
        # NOTE: it is assumed that `AttributeTypes` and
        # `AttributeConstraints` modules are included
        column_type ||= model.attribute_type(attribute)

        case column_type
        when :boolean
          :checkbox
        when :date, :time, :datetime
          column_type
        when :integer
          :number
        when :string
          case model.attribute_constraints_on(attribute)[:format]
          when :email
            :email
          else
            :text
          end
        when :text
          :text_area
        else
          :text
        end
      end

      def attribute_in_description(object, attribute, hints = {})
        object_class = object.class

        unless column_type = hints[:column_type]
          # NOTE: assumes that `AttributeTypes` module is included
          column_type = object_class.attribute_type(attribute)
        end

        name_html =
          attribute_name_as_label(object_class, attribute, column_type)

        value = object.public_send(attribute)

        html_classes = []

        case column_type
        when :boolean
          html_classes << :boolean
          value_html = value.nil? ? nil : text_from_boolean(value)
        when :date, :datetime
          html_classes << column_type
          value_html = l value, :format => :custom
        when :time
          html_classes << :time
          value_html = l value, :format => :time_of_the_day
        when :integer
          html_classes << :number
          value_html = value
        else
          html_classes << column_type
          value_html = value
        end

        readonly = object_class.readonly_attributes.include?(attribute.to_s)
        html_classes << :readonly if readonly

        haml :'/helper_partials/abstract_smarter_model/_attribute_in_description',
             :locals => { :name         => name_html,
                          :value        => value_html,
                          :html_classes => html_classes }
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

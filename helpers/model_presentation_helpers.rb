# encoding: UTF-8 (magic comment)

class CTT2013
  module ModelPresentationHelpers
    module AbstractSmarterModelHelpers
      def title_from_model_name(model)
        capitalize_first_letter_of(model.model_name.human)
      end

      def label_from_attribute_name(model, attribute, column_type = nil)
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

      def header_from_attribute_name(model, attribute)
        capitalize_first_letter_of(
          model.human_attribute_name(attribute))
      end

      HTML_CLASS_FROM_COLUMN_TYPE =
        [ :boolean, :date, :datetime, :string, :text, :time
        ].reduce(:integer => 'number') { |h, col_type|
          h[col_type] = col_type.to_s
          h
        }

      def html_class_from_column_type(column_type)
        HTML_CLASS_FROM_COLUMN_TYPE[column_type]
      end

      def input_html_type_for_attribute(model, attribute, column_type = nil)
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
          when :telephone
            :tel
          when :url
            :url
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
          label_from_attribute_name(object_class, attribute, column_type)

        value = object.public_send(attribute)

        html_classes = [html_class_from_column_type(column_type)]

        if object_class.readonly_attributes.include?(attribute.to_s)
          html_classes << 'readonly'
        end

        value_html = if value.nil?
                       nil
                     else
                       case column_type
                       when :boolean
                         text_from_boolean(value)
                       when :date, :datetime
                         l(value, :format => :custom)
                       when :time
                         l(value, :format => :time_of_the_day)
                       else
                         value
                       end
                     end

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

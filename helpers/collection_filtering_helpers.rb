# encoding: UTF-8 (magic comment)

require './lib/nested_arrays'

class CTT2013
  module CollectionFilteringHelpers
    def filtering_form(filtering_by,
                       filtering_values,
                       form_options = {})

      filtering_by = if filtering_by.first.is_a?(Array)
                       NestedArrays::s_unfold(filtering_by)
                     else
                       NestedArrays::p_unfold(filtering_by)
                     end

      filtering_values ||= {}

      params_key_prefix = "#{ form_options[:params_key_prefix] }" || 'filter'

      fields = []

      filtering_by.each do |model, *rest|
        model_options = rest.first.is_a?(Hash) ? rest.shift : {}
        attribute     = rest.first
        options       = rest.second || {}

        if model_options[:params_key_prefix] == false
          field_filtering_values = filtering_values || {}

          field_params_key_prefix = params_key_prefix
        else
          model_params_key =
            model_options[:params_key] || model.table_name

          field_filtering_values = filtering_values[model_params_key] || {}

          field_params_key_prefix =
            params_key_prefix + "[#{ model_params_key }]"
        end

        field = {}

        if assoc_reflection = model.reflect_on_association(attribute)
          assoc_model = assoc_reflection.klass
          assoc_foreign_key = assoc_reflection.foreign_key
          name_proc = options[:name_proc] || options[:name_attribute].to_proc

          field[:association_model] = assoc_model
          field[:header] = header_from_attribute_name(model, attribute)

          if field_filtering_values.key?(assoc_foreign_key)
            selected_values = Array(field_filtering_values[assoc_foreign_key])

            field[:shown_selected_values] =
              selected_values.map { |id|
                name_proc[assoc_model.find(id)]
              }.join(', ')
          end
          param_key = field_params_key_prefix + "[#{ assoc_foreign_key }]"

          field[:html_class] = 'association'
          field[:html_input_field] =
            filtering_association_select_field 'filter_form',
                                               param_key,
                                               assoc_model.default_order,
                                               name_proc,
                                               selected_values
        else
          attribute_type = model.attribute_type(attribute)

          field[:header] = header_from_attribute_name(model, attribute)

          if field_filtering_values.key?(attribute)
            selected_values = field_filtering_values[attribute]

            field[:shown_selected_values] =
              filtering_value(attribute_type, selected_values)
          end
          select_value_from =
            model.attribute_constraints_on(attribute)[:allowed_values]
          param_key = field_params_key_prefix + "[#{ attribute }]"

          field[:html_class] =
            html_class_from_column_type(attribute_type)
          field[:html_input_field] =
            if select_value_from
              filtering_attribute_select_field 'filter_form',
                                               param_key,
                                               attribute_type,
                                               selected_values,
                                               select_value_from
            else
              filtering_attribute_input_field 'filter_form',
                                              param_key,
                                              attribute_type,
                                              selected_values,
                                              options[:html_input_options]
            end
        end

        fields << field
      end

      haml :'helper_partials/_filtering_form',
           :locals => { :filtering_fields  => fields,
                        :filter_applied    => !filtering_values.empty?,
                        :action_url        => form_options[:action_url],
                        :hidden_parameters => form_options[:hidden_parameters] }
    end

    def filtering_attribute_input_field(filter_form_id, param_key,
                                        attribute_type, selected_values,
                                        html_options = {})

      partial_locals = { :filter_form_id  => filter_form_id,
                         :param_key       => param_key,
                         :selected_values => selected_values,
                         :id_prefix       => html_id_from_param_name(param_key) }

      case attribute_type
      when :string
        partial_locals[:autofocus] = html_options[:autofocus]

        haml :'helper_partials/_filtering_string_input_field',
             :locals => partial_locals
      when :boolean
        haml :'helper_partials/_filtering_boolean_input_field',
             :locals => partial_locals
      when :integer
        haml :'helper_partials/_filtering_integer_input_field',
             :locals => partial_locals
      when :date
        haml :'helper_partials/_filtering_date_input_field',
             :locals => partial_locals
      else
        raise 'Unrecognised attribute type for filtering field'
      end
    end

    def filtering_attribute_select_field(filter_form_id, param_key,
                                         attribute_type, selected_values,
                                         select_from)

      partial_locals = { :filter_form_id  => filter_form_id,
                         :param_key       => param_key,
                         :selected_values => selected_values,
                         :id_prefix       => html_id_from_param_name(param_key) }

      partial_locals[:select_from] = select_from
      haml :'helper_partials/_filtering_select_field',
           :locals => partial_locals
    end

    def filtering_association_select_field(filter_form_id, param_key,
                                           collection,     name_proc,
                                           selected_ids)

      haml :'helper_partials/_filtering_association_select_field',
           :locals => { :filter_form_id => filter_form_id,
                        :param_key      => param_key,
                        :collection     => collection,
                        :name_proc      => name_proc,
                        :selected_ids   => selected_ids,
                        :id_prefix      => html_id_from_param_name(param_key) }
    end

    def filtering_value(attribute_type, value_or_values)
      if value_or_values.is_a?(Enumerable)
        value_or_values.map { |value|
          "[#{ single_filtering_value(attribute_type, value) }]"
        }.join(', ')
      else
        single_filtering_value(attribute_type, value_or_values)
      end
    end

    def single_filtering_value(attribute_type, value)
      case attribute_type
      when :boolean
        text_from_boolean(value)
      when :integer
        "#{ value[:min] }..#{ value[:max] }"
      when :date
        parts = []
        if value.key?(:from)
          parts << "#{ t 'date.from' } #{ value[:from] }"
        end
        if value.key?(:until)
          parts << "#{ t 'date.until' } #{ value[:until] }"
        end
        parts.join(" ")
      else
        value
      end
    end
  end
end

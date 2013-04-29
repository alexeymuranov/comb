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
          field[:header] = label_from_attribute_name(model, attribute)

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

          field[:header] = label_from_attribute_name(model, attribute)

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
            filtering_attribute_field 'filter_form',
                                      param_key,
                                      attribute_type,
                                      selected_values,
                                      select_value_from
        end

        fields << field
      end

      haml :'helper_partials/_filtering_form',
           :locals => { :filtering_fields  => fields,
                        :filter_applied    => !filtering_values.blank?,
                        :action_url        => form_options[:action_url],
                        :hidden_parameters => form_options[:hidden_parameters] }
    end

    def filtering_attribute_field(filter_form_id, param_key, attribute_type,
                                  selected_values,
                                  select_from = nil)

      partial_locals = { :filter_form_id  => filter_form_id,
                         :param_key       => param_key,
                         :selected_values => selected_values,
                         :id_prefix       => html_id_from_param_name(param_key) }

      partial_locals[:column_type] = attribute_type
      if select_from
        partial_name = :'helper_partials/_filtering_select_field'
        partial_locals[:select_from] = select_from
      else
        partial_name = :'helper_partials/_filtering_input_field'
      end
      haml partial_name, :locals => partial_locals
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
      case attribute_type
      when :boolean
        text_from_boolean(value_or_values)
      when :integer
        "#{ value_or_values[:min] }..#{ value_or_values[:max] }"
      when :date
        parts = []
        if value_or_values.key?(:from)
          parts << "#{ t 'date.from' } #{ value_or_values[:from] }"
        end
        if value_or_values.key?(:until)
          parts << "#{ t 'date.until' } #{ value_or_values[:until] }"
        end
        parts.join(" ")
      else
        value_or_values
      end
    end
  end
end

# encoding: UTF-8 (magic comment)

class CTT2013
  module CollectionFilteringHelpers
    def filtering_form(model, filtering_parameters,
                       filtering_values  = {},
                       options = {})

      params_key_prefix = options[:params_key_prefix] || 'filter'

      fields = []

      filtering_parameters.each do |par|
        par = par.is_a?(Array) ? par.dup : [par]
        par_options = par.last.is_a?(Hash) ? par.last : {}

        mod = model
        val = filtering_values

        param_key_pref = params_key_prefix.is_a?(String) ?
                         params_key_prefix.dup : params_key_prefix.to_s

        attr = par.shift
        raise "Symbol expected here!" unless attr.is_a?(Symbol)

        field = {}

        loop do
          if (ref = mod.reflect_on_association(attr)).nil?
            attribute_type = mod.attribute_type(attr)
            field[:header] = label_from_attribute_name(mod, attr)
            if !val.nil? && val.key?(attr)
              selected_values = val[attr]
              field[:shown_selected_values] =
                filtering_value(attribute_type, selected_values)
            end
            select_value_from =
              mod.attribute_constraints_on(attr)[:allowed_values]
            param_key = param_key_pref + "[#{ attr }]"
            field[:html_class] =
              html_class_from_column_type(attribute_type)
            field[:html_input_field] =
              filtering_attribute_field 'filter_form',
                                        param_key,
                                        attribute_type,
                                        selected_values,
                                        select_value_from
            break
          else
            assoc_mod = ref.klass
            if par.first.is_a?(Symbol)
              mod = assoc_mod
              val_key = "#{ attr }_attributes_exist"
              val = val.nil? ? nil : val[val_key]
              param_key_pref << "[#{ val_key }]"
              attr = par.shift
              next
            else
              name_attribute = par_options[:name_attribute]
              field[:association_model] = assoc_mod
              field[:header] = label_from_attribute_name(mod, attr)
              if !val.nil? && val.key?(ref.foreign_key)
                selected_values = Array(val[ref.foreign_key])
                field[:shown_selected_values] =
                  selected_values.map { |id|
                    assoc_mod.find(id).public_send(name_attribute)
                  }.join(', ')
              end
              param_key = param_key_pref + "[#{ ref.foreign_key }]"
              field[:html_class] = 'association'
              field[:html_input_field] =
                filtering_association_select_field 'filter_form',
                                                   param_key,
                                                   assoc_mod.default_order,
                                                   name_attribute,
                                                   selected_values
              break
            end
          end
        end

        fields << field
      end

      haml :'helper_partials/_filtering_form',
           :locals => { :filtering_fields  => fields,
                        :filter_applied    => !filtering_values.blank?,
                        :action_url        => options[:action_url],
                        :hidden_parameters => options[:hidden_parameters] }
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
                                           collection,     name_attribute,
                                           selected_ids)

      haml :'helper_partials/_filtering_association_select_field',
           :locals => { :filter_form_id => filter_form_id,
                        :param_key      => param_key,
                        :collection     => collection,
                        :name_attribute => name_attribute,
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

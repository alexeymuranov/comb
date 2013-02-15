# encoding: UTF-8 (magic comment)

require 'i18n' # Internationalisation

class CTT2013
  module Helpers
    # Patched url helper to work around missing sub URI part
    def fixed_url(path)
      url(path, false, false).sub(/\A\//, BASE_URL)
    end

    def input_tag(type, name, value = nil, options = {})
      options.update :type => type, :name => name, :value => value
      haml "%input{options}", :locals => { :options => options }
    end

    def hidden_fields_from_nested_hash(hash, options = {})
      hidden_field_tags = []
      param_name_value_pairs_from_nested_hash(hash).each do |name, value|
        if value.is_a?(Array)
          name << '[]'
          value.each do |v|
            hidden_field_tags << input_tag(:hidden, name, v, options)
          end
        else
          hidden_field_tags << input_tag(:hidden, name, value, options)
        end
      end

      hidden_field_tags.join
    end

    def filtering_form(model, filtering_parameters,
                       filtering_values  = {},
                       params_key_prefix = 'filter')

      fields = []

      filtering_parameters.each do |par|
        par = par.is_a?(Array) ? par.dup : [par]
        options = par.last.is_a?(Hash) ? par.last : {}

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
              name_attribute = options[:name_attribute]
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
           :locals => { :filtering_fields => fields,
                        :filter_applied   => !filtering_values.blank? }
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

    module_function

      # Delegate translation helper to I18n
      def t(*args); I18n.t(*args) end

      # Delegate format localisation helper to I18n
      def l(*args); I18n.l(*args) end

      def text_from_boolean(bool, options = {})
        bool ? "✓#{ t(:yes, options) }" : t(:no, options)
      end

      def capitalize_first_letter_of(str)
        unless str.empty?
          str = ActiveSupport::Multibyte::Chars.new(str)
          str[0] = str[0].upcase
          str.to_s
        end
      end

      def html_id_from_param_name(name)
        name.to_s.gsub('[]','_').gsub(']','').gsub(/[^-a-zA-Z0-9:._]/, "_")
      end

      # Parse page name to determine I18n localisation scope
      def page_i18n_scope(page)
        'pages.' + page.to_s.gsub(?/, ?.)
      end

      def simple_fixed_url(path)
        path.sub(/\A\//, BASE_URL)
      end

      def param_name_value_pairs_from_nested_hash(nested_hash, key_prefix = '')
        format_key = if key_prefix.blank?
                       lambda { |k| k.to_s }
                     else
                       lambda { |k| "#{ key_prefix }[#{ k }]" }
                     end

        {}.tap do |flat_hash|
          nested_hash.each_pair do |k, v|
            k = format_key[k]
            if v.is_a?(Hash)
              flat_hash.merge!(param_name_value_pairs_from_nested_hash(v, k))
            else
              flat_hash[k] = v
            end
          end
        end
      end

  end
end

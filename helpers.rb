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

    def filtering_form(model,
                       attributes,
                       association_attributes = [],
                       filtering_values       = {})

      haml :'helper_partials/_filtering_form',
           :locals => { :model                  => model,
                        :attributes             => attributes,
                        :association_attributes => association_attributes,
                        :filtering_values       => filtering_values }
    end

    def filtering_field(filter_form_id,
                        attr,
                        column_type,
                        value_or_values,
                        name_prefix = 'filter',
                        select_from = nil)

      partial_locals = { :filter_form_id  => filter_form_id,
                         :attr            => attr,
                         :column_type     => column_type,
                         :value_or_values => value_or_values,
                         :name_prefix     => name_prefix,
                         :id_prefix       => html_id_from_param_name(name_prefix) }
      if select_from
        partial_name = :'helper_partials/_filtering_select_field'
        partial_locals[:select_from] = select_from
      else
        partial_name = :'helper_partials/_filtering_input_field'
      end
      haml partial_name, :locals => partial_locals
    end

    def filtering_value(column_type, value_or_values)
      haml :'helper_partials/_filtering_value',
           :locals => { :column_type     => column_type,
                        :value_or_values => value_or_values }
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

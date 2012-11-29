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

# encoding: UTF-8 (magic comment)

class CTT2013
  module FormHelpers

    def input_tag(type, name, value = nil, options = {})
      if [true, false].include? value
        value = value ? 1 : 0
      end
      options.update :type  => type,
                     :name  => name,
                     :value => value
      haml "%input{ options }", :locals => { :options => options }
    end

    # def hidden_field_tag(name, value, options = {})
    #   input_tag(:hidden, name, value, options)
    # end

    def hidden_fields_from_nested_hash(hash, options = {})
      [].tap do |hidden_field_tags|
        param_name_value_pairs_from_nested_hash(hash).each do |name, value|
          if value.is_a?(Enumerable)
            name = "#{ name }[]"
            value.each do |v|
              hidden_field_tags << input_tag(:hidden, name, v, options)
            end
          else
            hidden_field_tags << input_tag(:hidden, name, value, options)
          end
        end
      end.join("\n")
    end

    module_function

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

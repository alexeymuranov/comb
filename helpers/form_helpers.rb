# encoding: UTF-8 (magic comment)

class CTT2013::Application
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

    def hidden_fields_from_flat_hash(hash, options = {})
      hash.reduce([]) { |tags_memo, name__value|
        name, value = name__value
        if value.is_a?(Enumerable)
          name = "#{ name }[]"
          value.reduce(tags_memo) { |tm, v|
            tm << input_tag(:hidden, name, v, options)
          }
        else
          tags_memo << input_tag(:hidden, name, value, options)
        end
      }.join("\n")
    end

    def hidden_fields_from_nested_hash(hash, options = {})
      hidden_fields_from_flat_hash(
        param_name_value_pairs_from_nested_hash(hash), options)
    end

    def url_query_from_flat_hash(hash)
      hash.reduce([]) { |query_fragments_memo, name__value|
        name, value = name__value
        name = CGI::escape(name)
        if value.is_a?(Enumerable)
          name = "#{ name }[]"
          value.reduce(query_fragments_memo) { |qfm, v|
            qfm << "#{ name }=#{ CGI::escape(v.to_s) }"
          }
        else
          query_fragments_memo << "#{ name }=#{ CGI::escape(value.to_s) }"
        end
      }.join('&')
    end

    def url_query_from_nested_hash(hash)
      url_query_from_flat_hash(param_name_value_pairs_from_nested_hash(hash))
    end

    module_function

      def param_name_value_pairs_from_nested_hash(nested_hash, key_prefix = '')
        format_key = if key_prefix.blank?
                       lambda { |k| k.to_s }
                     else
                       lambda { |k| "#{ key_prefix }[#{ k }]" }
                     end

        nested_hash.reduce({}) { |flat_hash_memo, key__value|
          k, v = key__value
          k = format_key[k]
          if v.is_a?(Hash)
            flat_hash_memo.merge!(
              param_name_value_pairs_from_nested_hash(v, k))
          else
            flat_hash_memo[k] = v
            flat_hash_memo
          end
        }
      end

  end
end

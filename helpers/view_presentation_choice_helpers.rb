# encoding: UTF-8 (magic comment)

class CTT2013::Application
  module ViewPresentationChoiceHelpers
    def presentation_choice_form(available_formats, current_format, options = {})
      params_key_prefix = options[:params_key_prefix] || 'view'
      params_key_from_hash_key =
        if params_key_prefix.empty?
          lambda { |key| key.to_s }
        else
          lambda { |key| "#{ params_key_prefix }[#{ key }]" }
        end
      haml :'helper_partials/_presentation_choice_form',
           :locals => { :params_key_from_hash_key => params_key_from_hash_key,
                        :available_formats        => available_formats,
                        :current_format           => current_format,
                        :hidden_parameters        => options[:hidden_parameters] }
    end
  end
end

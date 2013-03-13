# encoding: UTF-8 (magic comment)

class CTT2013
  module ViewPaginationHelpers
    def paginating_form(paginating_parameters = {}, options = {})
      page_count = paginating_parameters[:page_count]
      per_page   = paginating_parameters[:per_page] || 1
      page       = paginating_parameters[:page] || 1
      params_key_prefix = options[:params_key_prefix] || 'view'
      params_key_from_hash_key =
        if params_key_prefix.empty?
          lambda { |key| key.to_s }
        else
          lambda { |key| "#{ params_key_prefix }[#{ key }]" }
        end
      page_ranges_before =
        if page > 12
          [[1], (page - 9)..(page - 1)]
        else
          [1..(page - 1)]
        end
      page_ranges_after  =
        if page < page_count - 11
          [(page + 1)..(page + 9), [page_count]]
        else
          [(page + 1)..page_count]
        end
      haml :'helper_partials/_paginating_form',
           :locals => { :params_key_from_hash_key => params_key_from_hash_key,
                        :per_page                 => per_page,
                        :active_page              => page,
                        :page_ranges_before       => page_ranges_before,
                        :page_ranges_after        => page_ranges_after,
                        :action_url               => options[:action_url],
                        :hidden_parameters        => options[:hidden_parameters] }
    end
  end
end

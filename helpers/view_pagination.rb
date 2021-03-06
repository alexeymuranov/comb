# encoding: UTF-8 (magic comment)

require_relative 'init'

module CTT2013::Helpers
  module ViewPagination
    def paginating_form(page_count = 1, paginating_parameters = {}, options = {})
      per_page = paginating_parameters[:per_page] || 1
      page     = paginating_parameters[:page]     || 1
      params_key_prefix = options[:params_key_prefix] || 'view'
      params_key_from_hash_key =
        if params_key_prefix.empty?
          lambda{|key| key.to_s }
        else
          lambda{|key| "#{ params_key_prefix }[#{ key }]" }
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
                        :current_page             => page,
                        :page_ranges_before       => page_ranges_before,
                        :page_ranges_after        => page_ranges_after,
                        :hidden_parameters        => options[:hidden_parameters] }
    end
  end
end

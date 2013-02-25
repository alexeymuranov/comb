# encoding: UTF-8 (magic comment)

class CTT2013
  module ViewPaginationHelpers
    def paginating_form(paginating_parameters = {}, options = {})
      per_page = paginating_parameters[:per_page] || 20
      page     = paginating_parameters[:page] || 1
      params_key_prefix = options[:params_key_prefix] || 'view'
      haml :'helper_partials/_paginating_form',
           :locals => { :params_key_prefix => params_key_prefix,
                        :per_page          => per_page,
                        :page              => page,
                        :hidden_parameters => options[:hidden_parameters] }
    end
  end
end

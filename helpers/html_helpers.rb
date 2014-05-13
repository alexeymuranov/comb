# encoding: UTF-8 (magic comment)

require_relative 'init'

module CTT2013::Helpers
  module HTML
    module_function

      def html_id_from_param_name(name)
        name.to_s.gsub('[]','_').gsub(']','').gsub(/[^-a-zA-Z0-9:._]/, "_")
      end

  end
end

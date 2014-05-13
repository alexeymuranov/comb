# encoding: UTF-8 (magic comment)

class CTT2013::Application
  module HTMLHelpers
    module_function

      def html_id_from_param_name(name)
        name.to_s.gsub('[]','_').gsub(']','').gsub(/[^-a-zA-Z0-9:._]/, "_")
      end

  end
end

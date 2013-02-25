# encoding: UTF-8 (magic comment)

require 'i18n' # Internationalisation

class CTT2013
  module URLHelpers
    # Patched url helper to work around missing sub URI part
    def fixed_url(path)
      url(path, false, false).sub(/\A\//, BASE_URL)
    end

    module_function

      def simple_fixed_url(path)
        path.sub(/\A\//, BASE_URL)
      end

  end
end

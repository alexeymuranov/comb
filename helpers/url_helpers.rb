# encoding: UTF-8 (magic comment)

require 'i18n' # Internationalisation

class CTT2013::Application
  module URLHelpers
    # Patched url helper to work around missing sub URI part
    def fixed_url(path)
      url(path, false, false).sub(/\A\//, CTT2013::BASE_URL)
    end

    def fixed_url_with_locale(path, locale = locale)
      # The default value of `locale` is the value of the private method with the same name.
      fixed_url("/#{ locale }#{ path }")
    end

    module_function

      def simple_fixed_url(path)
        path.sub(/\A\//, CTT2013::BASE_URL)
      end

  end
end

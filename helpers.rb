# encoding: UTF-8 (magic comment)

require 'i18n' # Internationalisation

class CTT2013
  module Helpers
    # Delegate translation helper to I18n
    def t(*args); I18n.t(*args) end

    # Delegate format localisation helper to I18n
    def l(*args); I18n.l(*args) end

    def text_from_boolean(bool, options = {})
      bool ? "✓#{ t(:yes, options) }" : t(:no, options)
    end

    def capitalize_first_letter_of(str)
      unless str.empty?
        str = ActiveSupport::Multibyte::Chars.new(str)
        str[0] = str[0].upcase
        str.to_s
      end
    end

    # Patched url helper to work around missing sub URI part
    def fixed_url(path)
      url(path, false, false).sub(/\A\//, BASE_URL)
    end
  end
end

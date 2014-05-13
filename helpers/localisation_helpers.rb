# encoding: UTF-8 (magic comment)

require 'i18n' # Internationalisation

class CTT2013::Application
  module LocalisationHelpers

    module_function

      # Delegate translation helper to I18n
      def t(*args); I18n.t(*args) end

      # Delegate format localisation helper to I18n
      def l(*args); I18n.l(*args) end

      # Parse page name to determine I18n localisation scope
      def page_i18n_scope(page)
        'pages.' + page.gsub('/', '.')
      end

  end
end

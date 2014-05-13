# encoding: UTF-8 (magic comment)


require_relative 'init'

module CTT2013::Helpers
  module DataPresentation
    module_function

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
  end
end

# encoding: UTF-8 (magic comment)

require_relative 'init'

module CTT2013::Helpers
  module GoogleMaps
    module_function
      def map_url_for_address(address)
        "http://maps.google.fr/maps?q=#{ address.gsub(' ', '+') }"
      end

  end
end

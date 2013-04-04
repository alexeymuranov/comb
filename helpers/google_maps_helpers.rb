# encoding: UTF-8 (magic comment)

class CTT2013
  module GoogleMapsHelpers
    module_function
      def map_url_for_address(address)
        "http://maps.google.fr/maps?q=#{ address.gsub(' ', '+') }"
      end

  end
end

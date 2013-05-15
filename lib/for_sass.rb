# encoding: UTF-8 (magic comment)

require 'sass'
require './helpers/url_helpers'

# Custom sass functions
#
module ::Sass::Script::Functions
  def banner_url
    url = CTT2013::URLHelpers.simple_fixed_url('/images/bannerToulouse.jpg')
    ::Sass::Script::String.new("url('#{ url }');")
  end

  def footer_home_button_background_url
    url = CTT2013::URLHelpers.simple_fixed_url('/images/capitole.jpg')
    ::Sass::Script::String.new("url('#{ url }');")
  end
end

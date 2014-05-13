# encoding: UTF-8 (magic comment)

require 'sass'

# FIXME: it is bad to require a file in helpers/ from a file in lib/, IMO
require './helpers/url'

# Custom sass functions
#
module ::Sass::Script::Functions
  def banner_url
    url = CTT2013::Helpers::URL.simple_fixed_url('/images/bannerToulouse.jpg')
    ::Sass::Script::String.new("url('#{ url }');")
  end

  def footer_home_button_background_url
    url = CTT2013::Helpers::URL.simple_fixed_url('/images/capitole.jpg')
    ::Sass::Script::String.new("url('#{ url }');")
  end
end

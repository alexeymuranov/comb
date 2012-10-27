# encoding: UTF-8 (magic comment)

require 'sass'

# Needed for Bourbon SCSS library to be used correctly by `scss`:
require ::File.join(CTT2013.settings.views, 'stylesheets/bourbon/lib/bourbon')

# Custom sass functions
#
module ::Sass::Script::Functions
  def banner_url
    ::Sass::Script::String.new(
      "url('#{ CTT2013::BASE_URL }images/bannerToulouse.jpg');"
    )
  end

  def footer_home_button_background_url
    ::Sass::Script::String.new(
      "url('#{ CTT2013::BASE_URL }images/capitole.jpg');"
    )
  end
end

# encoding: UTF-8 (magic comment)

class CTT2013 < Sinatra::Base

  # Cache control
  before do
    cache_control :public, :must_revalidate, :max_age => 60
  end
end

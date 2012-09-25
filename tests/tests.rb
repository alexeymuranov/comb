require 'minitest/autorun'
require 'rack/test'
require_relative '../application'

ENV['RACK_ENV'] = 'test'

describe 'Test CTT2013 application' do
  include Rack::Test::Methods

  def self.app
    CTT2013
  end

  def app
    self.class.app
  end

  describe 'Static public pages' do
    app::STATIC_PUBLIC_PAGES.each do |page|
      app::LOCALES.each do |locale|
        app::LOCALE_URL_FRAGMENTS[locale].each do |l|
          app::PAGE_URL_FRAGMENTS[page].each do |p|
            url = "#{ app::REQUEST_BASE_URL }#{ l }#{ p }"
            it "#{ url } should respond OK" do
              get url
              assert last_response.ok?,
                "GET #{ url } should have responded OK, but reponded #{ last_response.status }."
              assert last_response.body.include?('Michel'),
                "GET #{ url } response should have contained 'Michel', but did not."
            end
          end
        end
      end
    end
  end

  describe 'Dynamic public pages' do
    before do
      app.connect_database
    end

    [:participants, :registration].each do |page|
      app::LOCALES.each do |locale|
        app::LOCALE_URL_FRAGMENTS[locale].each do |l|
          app::PAGE_URL_FRAGMENTS[:"#{ app::COMB_PAGE_PREFIX }#{ page }"].each do |p|
            url = "#{ app::REQUEST_BASE_URL }#{ l }#{ p }"
            it "#{ url } should respond OK" do
              get url
              assert last_response.ok?,
                "GET #{ url } should have responded OK, but reponded #{ last_response.status }."
              assert last_response.body.include?('Michel'),
                "GET #{ url } response should have contained 'Michel', but did not."
            end
          end
        end
      end
    end
  end
end

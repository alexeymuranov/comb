require 'minitest/autorun'
require 'rack/test'
require File.expand_path('../application.rb', File.dirname(__FILE__))

ENV['RACK_ENV'] = 'test'

describe 'Test CTT2013::Application application' do
  include Rack::Test::Methods

  def self.app
    CTT2013::Application
  end

  def app
    self.class.app
  end

  describe 'Static public pages' do
    app::STATIC_PUBLIC_PAGES.each do |page|
      app::LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
        app::PAGE_URL_FRAGMENTS[page].each do |p|
          url = "#{ app::BASE_URL }#{ l }#{ p }"
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

  describe 'Dynamic public pages' do
    ['participants', 'registration'].each do |page|
      app::LOCALE_FROM_URL_LOCALE_FRAGMENT.each_pair do |l, locale|
        app::PAGE_URL_FRAGMENTS["#{ app::COMB_PAGE_PREFIX }#{ page }"].each do |p|
          url = "#{ app::BASE_URL }#{ l }#{ p }"
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

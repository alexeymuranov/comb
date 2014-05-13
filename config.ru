# encoding: UTF-8 (magic comment)

# This file is used, for example, when deploying with Apache and Phusion
# Passenger.
#
# Some documentation:
#
# * https://github.com/rack/rack/wiki/(tutorial)-rackup-howto
# * http://www.sinatrarb.com/intro.html#When%20to%20use%20a%20config.ru?

require 'bundler'

# ENV['RACK_ENV'] = 'production'
Bundler.setup(:default, ENV['RACK_ENV'])

require File.expand_path('application.rb', File.dirname(__FILE__))

# This seems to be needed to automatically close connections at the end of
# each request.  Not sure if and how this works.  This does not work when
# the applicaiton is run from the command line with "Thin" web server.
# For that case, connections need to be closed explicitely in an "after"
# filter.
use ActiveRecord::ConnectionAdapters::ConnectionManagement

run CTT2013.new

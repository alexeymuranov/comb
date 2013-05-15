# encoding: UTF-8 (magic comment)

# This file is used for Phusion Passenger, or if deploying to heroku.com

# ENV['RACK_ENV'] = 'production'

require 'rubygems'
require 'sinatra'
require './application.rb'

# This seems to be needed to automatically close connections at the end of
# each request.  Not sure if and how this works.  This does not work when
# the applicaiton is run from the command line with "Thin" web server.
# For that case, connections need to be closed explicitely in an "after"
# filter.
use ActiveRecord::ConnectionAdapters::ConnectionManagement

run CTT2013

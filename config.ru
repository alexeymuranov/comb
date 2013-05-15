# encoding: UTF-8 (magic comment)

# This file is used for Phusion Passenger, or if deploying to heroku.com

# ENV['RACK_ENV'] = 'production'

require 'rubygems'
require 'sinatra'
require './application.rb'


run CTT2013

# encoding: UTF-8 (magic comment)

require 'sqlite3'
require 'logger'
require 'active_record'

require_relative 'models'

class CTT2013::Application
  environment = settings.environment

  ActiveRecord::Base.logger = Logger.new("log/#{ environment }.log")
  ActiveRecord::Base.configurations = YAML::load(IO.read('config/database.yml'))
  ActiveRecord::Base.establish_connection(environment)
end

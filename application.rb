# encoding: UTF-8 (magic comment)

Encoding.default_external = Encoding::UTF_8
# Encoding.default_internal = Encoding::UTF_8

require 'set' # to use Set data structure

require 'digest' # to hash passwords

require 'yaml'

require 'cgi' # "Common Gateway Interface", HTTP tools (escape query string, for example)

require 'csv' # to generate CSV files for download

require 'haml'
require 'sass'
require 'redcarpet' # Markdown

# XXX: Because of some bug, 'active_record' needs to be required before 'pony'.
require 'active_record'
require 'pony' # Email

require 'reverse_markdown' # HTML to markdown for text email body

require_relative 'app_config'

require_relative 'lib/for_sass'

require_relative 'lib/simple_relation_filter'

require_relative 'models/init'

require_relative 'helpers/init'

require_relative 'route_handlers/init'

if __FILE__ == $0
  CTT2013.run!
end

source 'https://rubygems.org'

# Rake (like "make"), to use Rakefile (Makefile for Ruby):
gem 'rake'

gem 'sinatra'

group :test do
  # Testing
  gem 'rack-test'
end

group :development, :test do
  # Web server (instead of WEBrick):
  gem 'thin'
end

# Database interaction:
gem 'activerecord', '~> 3.2.13'
gem 'sqlite3'

# HTML/CSS from templates:
gem 'haml'
gem 'redcarpet'
gem 'sass'

# HTML to Markdown
gem 'reverse_markdown'

# Mixin library for Sass:
gem 'bourbon'

# Localizations:
gem 'i18n'

# Email:
gem 'pony'

# Session-based flash messages
gem 'sinatra-flash'

group :development do
  # Ruby Debugger:
  gem 'debugger'

  # Better error pages in development:
  gem 'better_errors'
  # Causes the server fail to start:
  # gem 'binding_of_caller' # used by better_errors
end

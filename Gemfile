source :rubygems

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
gem 'activerecord'
gem 'sqlite3'

# HTML/CSS from templates:
gem 'haml'
gem 'redcarpet'
gem 'sass'

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
  case RUBY_VERSION[0..2]
  when '1.8'
    gem 'ruby-debug'
  when '1.9'
    gem 'debugger'
  end
end

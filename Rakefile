# encoding: UTF-8 (magic comment)

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "tests/*.rb"
end

namespace :db do
  task :environment do
    require_relative 'app_config'
    require_relative 'models/init'
  end

  desc 'create an ActiveRecord migration in ./db/migrate'
  task :create_migration do
    name = ENV['NAME']
    if name.nil?
      raise 'No NAME specified. Example usage: `rake db:create_migration NAME=create_users`'
    end

    migrations_dir = File.join('db', 'migrate')
    version = ENV['VERSION'] || Time.now.utc.strftime('%Y%m%d%H%M%S')
    filename = "#{ version }_#{ name }.rb"
    migration_class = name.split('_').map(&:capitalize).join

    FileUtils.mkdir_p(migrations_dir)

    File.open(File.join(migrations_dir, filename), 'w') do |file|
      file.write <<-MIGRATION.strip_heredoc
        class #{ migration_class } < ActiveRecord::Migration
          def up
          end

          def down
          end
        end
      MIGRATION
    end
  end

  desc 'migrate the database (use version with VERSION=n)'
  # NOTE: set 'RACK_ENV' environment variable to specify deployment
  # environment (:-\)
  # It can be 'development', 'test', 'production'.
  # The default is usually 'development'.
  # Example: rake RACK_ENV=test db:migrate
  task(:migrate => :environment) do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
    ActiveRecord::Migrator.migrate('db/migrate', version)
  end

  desc 'rolls back the migration (use steps with STEP=n)'
  task(:rollback => :environment) do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Migrator.rollback('db/migrate', step)
  end
end

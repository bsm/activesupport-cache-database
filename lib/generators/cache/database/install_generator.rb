require "rails/generators/active_record"

module Cache
  module Database
    module Generators
      class InstallGenerator < Rails::Generators::Base
        include ActiveRecord::Generators::Migration

        source_root File.join(__dir__, "templates")
        desc "Add migration for ActiveSupport::Cache::Database"

        def self.next_migration_number(path)
          next_migration_number = current_migration_number(path) + 1
          ActiveRecord::Migration.next_migration_number(next_migration_number)
        end

        def copy_migrations
          migration_template "create_table_for_cache.rb", "db/migrate/create_cache_database.rb"
        end
      end
    end
  end
end

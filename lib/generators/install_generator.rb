require "rails/generators"
require "rails/generators/migration"

module ActiveSupport
	module Cache::Database
		module Generators
			class InstallGenerator < Rails::Generators::Base
				source_roout File.join(__dir__, "templates")
				desc "Add migration for ActiveSupport::Cache::Database"

				def self.next_migration_number(path)
					next_migration_number = current_migration_number(path) + 1
					ActiveRecord::Migration.next_migration_number(next_migration_number)
				end

				def copy_migrations
					migration_template "create_cache_database.rb", "db/migrate/create_cache_database.rb"
				end
			end
		end
	end
end

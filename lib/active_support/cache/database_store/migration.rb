require 'active_support/cache/database_store'

module ActiveSupport
  module Cache
    class DatabaseStore < Store
      class Migration < ::ActiveRecord::Migration[5.2]
        def change
          create_table :activesupport_cache_entries, primary_key: 'key', id: :binary, limit: 255 do |t|
            t.binary :value, null: false
            t.string :version, index: true
            t.timestamp :created_at, null: false, index: true
            t.timestamp :expires_at
          end

          if mysql?
            # MySQL and MariaDB don't support partial indexes
            add_index :activesupport_cache_entries, :expires_at
          else
            # For Sqlite3, PostgreSQL we use partial index, because expires_at column can be null it would be wasteful to include it in index
            add_index :activesupport_cache_entries, :expires_at, where: 'expires_at IS NOT NULL'
          end
        end

        private

        def adapter
          if ActiveRecord::VERSION::STRING.to_f >= 6.1
            ActiveRecord::Base.connection_db_config.adapter.to_s
          else
            ActiveRecord::Base.connection_config[:adapter].to_s
          end
        end

        def mysql?
          adapter =~ /mysql/
        end
      end
    end
  end
end

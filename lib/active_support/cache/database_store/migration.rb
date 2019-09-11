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
            t.timestamp :expires_at, index: true
          end
        end
      end
    end
  end
end

require 'active_support/cache/database_store'

class Migration < ::ActiveRecord::Migration[5.2]
  def change
    create_table :activesupport_cache_entries, primary_key: 'key', id: :binary, limit: 255 do |t|
      t.binary :value, null: false
      t.string :version, index: true
      t.timestamp :created_at, null: false, index: true
      t.timestamp :expires_at, index: true
    end

    # Unlogged tables come with at least 50% write performance increase, but come with multiple downsides you need to be aware off:
    # - No validation, data will be lost in case of forced restart.
    # - No replication to read replicas
    #
    # Since we're working with cache here, these drawbacks are accaptable. But you can turn that off, just comment next line out.
    ActiveRecord::Base.connection.execute("ALTER TABLE activesupport_cache_entries SET UNLOGGED")
  end
end

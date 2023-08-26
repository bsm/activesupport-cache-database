class CreateTableForCache < ActiveRecord::Migration[5.2]
  def change
    create_table :activesupport_cache_entries, primary_key: 'key', id: :binary, limit: 255 do |t|
      t.binary :value, null: false
      t.string :version
      t.timestamp :created_at, null: false, index: true
      t.timestamp :expires_at
    end

    add_index :activesupport_cache_entries, :expires_at, where: 'expires_at IS NOT NULL'
    add_index :activesupport_cache_entries, :version, where: 'version IS NOT NULL'

    # if your using Postgres you might want to turn cache table into unlogged tables.
    # This comes with 50% write performance improvement, but comes with multiple
    # downsides you need to be aware off:
    # - No validation, data will be lost in case of forced restart.
    # - No replication to read replicas
    #
    # Since we're working with cache here, these drawbacks seem accaptable.
    #
    # Uncomment a following line if those are acceptable for you:
    # ActiveRecord::Base.connection.execute("ALTER TABLE activesupport_cache_entries SET UNLOGGED")
  end
end

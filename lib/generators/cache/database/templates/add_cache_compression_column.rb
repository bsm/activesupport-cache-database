class AddCacheCompressionColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :activesupport_cache_entries, :compression, :string, null: true
  end
end

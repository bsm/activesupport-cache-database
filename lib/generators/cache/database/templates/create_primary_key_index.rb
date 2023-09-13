class CreatePrimaryKeyIndex < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE INDEX activesupport_cache_entries_key_index ON public.activesupport_cache_entries USING HASH (key);
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX activesupport_cache_entries_key_index;
    SQL
  end
end

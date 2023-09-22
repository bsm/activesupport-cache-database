require 'active_support/cache'
require 'active_record'
require 'active_support/gzip'

module ActiveSupport
  module Cache
    # A cache store implementation which stores everything in the database, using ActiveRecord as the backend.
    #
    # DatabaseStore implements the Strategy::LocalCache strategy which implements
    # an in-memory cache inside of a block.
    class DatabaseStore < Store
      prepend Strategy::LocalCache

      autoload :Model, 'active_support/cache/database_store/model'

      COMPRESSION_HANDLERS = { 'gzip'  => ActiveSupport::Gzip }.freeze

      # Advertise cache versioning support.
      def self.supports_cache_versioning?
        true
      end

      # param [Hash] options options
      # option options [Class] :model model class. Default: ActiveSupport::Cache::DatabaseStore::Model
      def initialize(options = nil)
        @model = (options || {}).delete(:model) || Model
        @compression = (options || {}).delete(:compression)&.to_s
        super(options)
      end

      # Preemptively iterates through all stored keys and removes the ones which have expired.

      # params [Hash] options
      # option options [String] :namespace
      # option options [ActiveSupport::Duration] :created_before - provide a time duration after record without expire_at date will get removed.
      def cleanup(options = nil)
        options = merged_options(options)
        scope = @model.expired

        if (created_before = options[:created_before])
          scope = scope.or(@model.created_before(created_before))
        end

        if (namespace = options[:namespace])
          scope = scope.namespaced(namespace)
        end

        scope.delete_all
      end

      # Clears the entire cache. Be careful with this method.
      #
      # params [Hash] options
      # option options [String] :namespace
      #
      # @return [Boolean]
      def clear(options = nil)
        options = merged_options(options)
        if (namespace = options[:namespace])
          @model.namespaced(namespace).delete_all
        else
          @model.truncate!
        end
        true
      end

      # Calculates the number of entries in the cache.
      def count(options = nil)
        options = merged_options(options)
        scope = @model.all
        if (namespace = options[:namespace])
          scope = scope.namespaced(namespace)
        end
        scope = scope.fresh unless options[:all]
        scope.count
      end

      # Increments an integer value in the cache.
      def increment(name, amount = 1, options = nil)
        options = merged_options(options)
        scope = @model.all
        if (namespace = options[:namespace])
          scope = scope.namespaced(namespace)
        end

        entry = Entry.new(amount, **options.merge(version: normalize_version(name, options)))

        # Integer and float entries do not warrant compression so that upsert remains possible with a DB-drive increment
        attrs = { key: normalize_key(name, options),  **entry_attributes(entry) }
        scope.upsert(attrs, on_duplicate: Arel.sql(sanitize_sql_array(['value = EXCLUDED.value + ?', amount])))
      end

      # Decrements an integer value in the cache.
      def decrement(name, amount = 1, options = nil)
        increment(name, -amount, options)
      end

      private

      def normalize_key(name, options = nil)
        key = super.to_s
        raise ArgumentError, 'Namespaced key exceeds the length limit' if key && key.bytesize > 255

        # `key` is actually a BLOB column, with some DBs (such as SQLite) we need to explicitly
        # tag the string as binary so that Arel can properly escape it for a SELECT query
        key.b
      end

      def read_entry(key, _options = nil)
        from_record @model.where(key: key).first
      end

      def write_entry(key, entry, _options = nil)
        record = @model.where(key: key).first_or_initialize
        record.update!(**entry_attributes(entry))
      rescue ActiveRecord::RecordNotUnique
        # If two servers initialize a new record with the same cache key and try to save it,
        # the saves will race. We do not need to ensure a specific save wins, but we do need to ensure
        # that at least one of the saves succeeds and that none of the saves raise an exception.
        # In practive it means that if there alread was a save that "won" from us and completed earlier
        # we don't need to do anything.
        true
      end

      def delete_entry(key, _options = nil)
        @model.where(key: key).destroy_all
      end

      def write_multi_entries(hash, **_options)
        entries = hash.map {|key, entry| { key: key, created_at: Time.zone.now, **entry_attributes(entry) } }

        # In rails 7, we can use update_only not to do anything. But for the sakes of compatibility, we don't use any additional parameters.
        @model.upsert_all(entries)
      end

      def entry_attributes(entry)
        expires_at = Time.zone.at(entry.expires_at) if entry.expires_at

        compression_attributes(entry.value).merge(version: entry.version.presence, expires_at: expires_at)
      end

      def read_multi_entries(names, options)
        keyed = {}
        names.each do |name|
          version = normalize_version(name, options)
          keyed[normalize_key(name, options)] = { name: name, version: version }
        end

        results = {}
        @model.where(key: keyed.keys).find_each do |rec|
          name, version = keyed[rec.key].values_at(:name, :version)
          entry = from_record(rec)
          next if entry.nil?

          if entry.expired?
            delete_entry(rec.key, **options)
          elsif entry.mismatched?(version)
            # Skip mismatched versions
          else
            results[name] = entry.value
          end
        end
        results
      end


      def compression_attributes(value)
        binary = Marshal.dump(value)

        if value.is_a?(Numeric)
          { value: binary }
        elsif @compression && binary.bytesize >= 1024
          handler = COMPRESSION_HANDLERS[@compression]
          { compression: @compression, value: handler.compress(binary) }
        else
          { value: binary }
        end
      end

      def decompress(record)
        return Marshal.load(record.value) if record.compression.nil?

        COMPRESSION_HANDLERS.fetch(record.compression).decompress(record.value)
      end

      def from_record(record)
        return unless record

        entry = Entry.new(decompress(record), version: record.version)
        entry.expires_at = record.expires_at
        entry
      end
    end
  end
end

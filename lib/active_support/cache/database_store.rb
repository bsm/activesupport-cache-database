require 'active_support/cache'
require 'active_record'

module ActiveSupport
  module Cache
    # A cache store implementation which stores everything in the database, using ActiveRecord as the backend.
    #
    # DatabaseStore implements the Strategy::LocalCache strategy which implements
    # an in-memory cache inside of a block.
    class DatabaseStore < Store
      prepend Strategy::LocalCache

      autoload :Model, 'active_support/cache/database_store/model'
      autoload :Migration, 'active_support/cache/database_store/migration'

      # Advertise cache versioning support.
      def self.supports_cache_versioning?
        true
      end

      # param [Hash] options options
      # option options [Class] :model model class. Default: ActiveSupport::Cache::DatabaseStore::Model
      def initialize(options = nil)
        @model = (options || {}).delete(:model) || Model
        super(options)
      end

      # Preemptively iterates through all stored keys and removes the ones which have expired.
      def cleanup(options = nil)
        options = merged_options(options)
        scope = @model.expired
        if (namespace = options[:namespace])
          scope = scope.namespaced(namespace)
        end
        scope.delete_all
      end

      # Clears the entire cache. Be careful with this method.
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

      private

      def normalize_key(name, options = nil)
        key = super.to_s
        raise ArgumentError, 'Namespaced key exceeds the length limit' if key && key.bytesize > 255

        key
      end

      def read_entry(key, _options = nil)
        from_record @model.where(key: key).first
      end

      def write_entry(key, entry, _options = nil)
        record = @model.where(key: key).first_or_initialize
        expires_at = Time.zone.at(entry.expires_at) if entry.expires_at
        record.update! value: Marshal.dump(entry.value), version: entry.version.presence, expires_at: expires_at
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

      def from_record(record)
        return unless record

        entry = Entry.new Marshal.load(record.value), version: record.version
        entry.expires_at = record.expires_at
        entry
      end
    end
  end
end

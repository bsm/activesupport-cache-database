require 'active_support/cache/database_store'

module ActiveSupport
  module Cache
    class DatabaseStore < Store
      class Model < ActiveRecord::Base
        self.table_name = 'activesupport_cache_entries'

        def self.truncate!
          connection.truncate(table_name)
        end

        scope :fresh, -> { where(arel_table[:expires_at].gt(Time.zone.now)) }
        scope :expired, -> { where(arel_table[:expires_at].lteq(Time.zone.now)) }
        scope :outdated, -> (date = 1.month.ago) { where(arel_table[:created_at].lt(date)) }

        def self.namespaced(namespace)
          prefix = "#{namespace}:"
          clause = ::Arel::Nodes::NamedFunction.new('SUBSTR', [arel_table[:key], 1, prefix.bytesize])
          where clause.eq(prefix)
        end


      end
    end
  end
end

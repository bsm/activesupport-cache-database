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
        scope :created_before, ->(date = 1.month.ago) { where(arel_table[:created_at].lt(date)) }

        def self.namespaced(namespace)
          case ActiveRecord::Base.connection.adapter_name
          when 'PostgreSQL'
            ifx = Arel::Nodes::InfixOperation.new('IN', Arel::Nodes.build_quoted(namespace), arel_table[:key])
            where(Arel::Nodes::NamedFunction.new('POSITION', [ifx]).eq(1))
          else
            where(arel_table[:key].matches("#{namespace}:%"))
          end
        end
      end
    end
  end
end

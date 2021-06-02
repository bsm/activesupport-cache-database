# ActiveSupport::Cache::DatabaseStore

[![Test](https://github.com/bsm/activesupport-cache-database/actions/workflows/test.yml/badge.svg)](https://github.com/bsm/activesupport-cache-database/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

ActiveSupport::Cache::Store implementation backed by a database via ActiveRecord.

Tested with:

- PostgreSQL
- SQlite3
- MySQL/MariaDB

## Usage

Include the data migration:

```ruby
# db/migrate/20190908102030_create_activesupport_cache_entries.rb
require 'active_support/cache/database_store/migration'

class CreateActivesupportCacheEntries < ActiveRecord::Migration[5.2]
  def up
    ActiveSupport::Cache::DatabaseStore::Migration.migrate(:up)
  end

  def down
    ActiveSupport::Cache::DatabaseStore::Migration.migrate(:down)
  end
end
```

Open and use the new cache instance:

```ruby
cache = ActiveSupport::Cache::DatabaseStore.new namespace: 'my-scope'
value = cache.fetch('some-key') { 'default' }
```

To use as a Rails cache store, simply use a new instance. Please keep in mind
that, for performance reasons, your database may not be the most suitable
general purpose cache backend.

```ruby
config.cache_store = ActiveSupport::Cache::DatabaseStore.new
```

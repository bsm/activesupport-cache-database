# ActiveSupport::Cache::DatabaseStore

[![Test](https://github.com/bsm/activesupport-cache-database/actions/workflows/test.yml/badge.svg)](https://github.com/bsm/activesupport-cache-database/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

ActiveSupport::Cache::Store implementation backed by a database via ActiveRecord.

Tested with:

- PostgreSQL
- SQlite3
- MySQL/MariaDB

## Install
Add gem to Gemfile and bundle install.

```gem 'activesupport-cache-database'```

This gem requires a database table `activesupport_cache_entries` to be created. To do so generate a migration that would create required table.

```rails generate cache:database:install```

Make sure to read through migration file, before running a migration. You might want to tweak it to fit your usecase.

`rails db:migrate`

## Usage

Open and use the new cache instance:
```ruby
cache = ActiveSupport::Cache::DatabaseStore.new namespace: 'my-scope'
value = cache.fetch('some-key') { 'default' }
```

To use as a Rails cache store, simply use a new instance.

```ruby
config.cache_store = ActiveSupport::Cache::DatabaseStore.new
```

## Maintenance
After you have started caching into the database, you will likely see the database size growing significantly. It is crucial to implement an effective strategy to evict the cache from your DB.

There may be a large number of cache entries that do not possess an `expires_at` value, so it will be necessary to decide on an optimal timeframe for storing your cache.

This next piece of code should be run periodically:
```
ActiveSupport::Cache::DatabaseStore.new.cleanup(
  created_before: 1.week.ago
)
```
Without providing a `created_before` value, only those caches with `expires_at` values will be cleaned, leaving behind plenty of dead cache.

If you're using PostgreSQL, consider running vacuum or pg_repack intermittently to delete data physically as well.


## Warning
There are two things you need to be aware about while using this gem:
- For performance reasons, your database may not be the most suitable general purpose cache backend. But in some cases, caching complex quieries in cache could be a good enough improvement.
- While already generally usable as a Rails cache store, this gem doesn't yet implement all required methods.

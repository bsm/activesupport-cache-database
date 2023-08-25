ENV['RACK_ENV'] ||= 'test'

require 'rspec'
require 'fileutils'
require 'activesupport_cache_database'
require 'active_support/testing/time_helpers'
require_relative '../lib/generators/cache/database/templates/create_table_for_cache'

Time.zone_default = Time.find_zone!('UTC')

database_url = ENV.fetch('DATABASE_URL') do
  path = File.expand_path('./test.sqlite3', __dir__)
  FileUtils.rm_f(path)
  "sqlite3://#{path}"
end
ActiveRecord::Base.configurations = { 'test' => { 'url' => database_url, 'pool' => 20 } }

ActiveRecord::Base.establish_connection :test
ActiveRecord::Base.connection.instance_eval do
  drop_table 'activesupport_cache_entries', if_exists: true
end
ActiveRecord::Migration.suppress_messages do
  CreateTableForCache.migrate(:up)
end

RSpec.configure do |c|
  c.after do
    ActiveSupport::Cache::DatabaseStore::Model.truncate!
  end
end

ModelWithKeyAndVersion = Struct.new(:cache_key, :cache_version)

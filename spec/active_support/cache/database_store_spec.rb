require 'spec_helper'
require_relative 'shared_database_store_examples'

RSpec.describe ActiveSupport::Cache::DatabaseStore do
  include_examples 'Database cache store with compression', 'plain'
  include_examples 'Database cache store with compression', 'gzip'

  it 'reads a cache entry having a different compression setting than the store configuration' do
    plain_store = described_class.new expires_in: 60
    gzip_store = described_class.new expires_in: 60, compression: 'gzip'

    source_object = { foo: 123 }
    plain_store.write('k', source_object)
    expect(plain_store.read('k')).to eq(source_object)
    expect(gzip_store.read('k')).to eq(source_object)

    gzip_store.write('k2', source_object)
    expect(plain_store.read('k2')).to eq(source_object)
    expect(gzip_store.read('k2')).to eq(source_object)
  end

  it 'applies gzip compression to the actual written entry' do
    gzip_store = described_class.new expires_in: 60, compression: 'gzip'
    source_object = { foo: 'you are welcome' }

    gzip_store.write('k3', source_object)

    last_inserted_model = ActiveSupport::Cache::DatabaseStore::Model.order('created_at DESC').first!
    expect(last_inserted_model.compression).to eq('gzip')

    decompressed_and_demarshaled_obj = Marshal.load(ActiveSupport::Gzip.decompress(last_inserted_model.value))
    expect(decompressed_and_demarshaled_obj).to eq(source_object)
  end

  it 'uses plain compression if none specified' do
    gzip_store = described_class.new expires_in: 60
    source_object = { foo: 'you are welcome' }

    gzip_store.write('k4', source_object)

    last_inserted_model = ActiveSupport::Cache::DatabaseStore::Model.order('created_at DESC').first!
    expect(last_inserted_model.compression).to eq('plain')
    decompressed_and_demarshaled_obj = Marshal.load(last_inserted_model.value)
    expect(decompressed_and_demarshaled_obj).to eq(source_object)
  end
end

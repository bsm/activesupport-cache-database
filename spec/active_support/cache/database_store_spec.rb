require 'spec_helper'
require_relative 'shared_database_store_examples'

RSpec.describe ActiveSupport::Cache::DatabaseStore do
  include_examples 'Database cache store with compression', 'plain'
  include_examples 'Database cache store with compression', 'gzip'

  it 'errors out for unsupported compression'  do
    expect {described_class.new expires_in: 60, compression: 'brotli'}.to raise_error(ArgumentError, 'invalid compression option "brotli"')
  end

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

  it "doesn't apply gzip compression to entry lower than 1024 bytes" do
    gzip_store = described_class.new expires_in: 60, compression: 'gzip'
    source_object = { foo: 'you are welcome' }

    gzip_store.write('k3', source_object)

    last_inserted_model = ActiveSupport::Cache::DatabaseStore::Model.order('created_at DESC').first!
    expect(last_inserted_model.compression).to be_nil

    decompressed_and_demarshaled_obj = Marshal.load(last_inserted_model.value)
    expect(decompressed_and_demarshaled_obj).to eq(source_object)
  end

  it 'applies gzip compression to Value larger than 1024 bytes' do
    gzip_store = described_class.new expires_in: 60, compression: 'gzip'
    source_object = {
      "employees": [
          {"firstName":"John", "lastName":"Doe", "age": 25, "address": "123 Maple Street, Anytown, Anystate, 12345", "jobTitle": "Software Developer", "startDate": "2010-01-01", "email": "john.doe@example.com", "phone": "123-456-7890"},
          {"firstName":"Anna", "lastName":"Smith", "age": 30, "address": "456 Oak Avenue, Sometown, Somestate, 67890", "jobTitle": "Product Manager", "startDate": "2012-02-02", "email": "anna.smith@example.com", "phone": "234-567-8901"},
          {"firstName":"Peter", "lastName":"Jones", "age": 35, "address": "789 Pine Lane, OtherTown, OtherState, 54321", "jobTitle": "Project Manager", "startDate": "2015-03-03", "email": "peter.jones@example.com", "phone": "345-678-9012"},
          {"firstName":"Maria", "lastName":"Rodriguez", "age": 40, "address": "321 Elm Drive, NewTown, NewState, 21234", "jobTitle": "Database Administrator", "startDate": "2011-04-04", "email": "maria.rodriguez@example.com", "phone": "456-789-0123"},
          {"firstName":"Paul", "lastName":"Johnson", "age": 45, "address": "654 Cedar Place, SmallTown, SmallState, 12123", "jobTitle": "Systems Administrator", "startDate": "2009-05-05", "email": "paul.johnson@example.com", "phone": "567-890-1234"},
          {"firstName":"Sandra", "lastName":"Lee", "age": 50, "address": "987 Birch Court, BigTown, BigState, 23241", "jobTitle": "Software Tester", "startDate": "2013-06-06", "email": "sandra.lee@example.com", "phone": "678-901-2345"}
      ]
    }

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
    expect(last_inserted_model.compression).to be_nil
    decompressed_and_demarshaled_obj = Marshal.load(last_inserted_model.value)
    expect(decompressed_and_demarshaled_obj).to eq(source_object)
  end
end

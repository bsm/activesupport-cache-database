module ActiveSupport::Cache::DatabaseStore::PlainHandler
  def self.compress(object)
    Marshal.dump(object)
  end

  def self.decompress(bytes)
    Marshal.load(bytes)
  end
end

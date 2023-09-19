module ActiveSupport::Cache::DatabaseStore::GzipHandler
  def self.compress(object)
    ActiveSupport::Gzip.compress(Marshal.dump(object))
  end

  def self.decompress(bytes)
    Marshal.load(ActiveSupport::Gzip.decompress(bytes))
  end
end

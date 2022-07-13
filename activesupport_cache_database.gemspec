Gem::Specification.new do |s|
  s.name          = 'activesupport_cache_database'
  s.version       = '0.3.0'
  s.authors       = ['Black Square Media Ltd']
  s.email         = ['info@blacksquaremedia.com']
  s.summary       = %(ActiveSupport::Cache::Store implementation backed by ActiveRecord.)
  s.description   = %(Use your DB as a cache store)
  s.homepage      = 'https://github.com/bsm/activesupport-cache-database'
  s.license       = 'Apache-2.0'

  s.files         = `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^spec/}) }
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.7'

  s.add_dependency 'activerecord', '>= 6.0'
  s.add_dependency 'activesupport', '>= 6.0'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop-bsm'
  s.add_development_dependency 'sqlite3'
  s.metadata['rubygems_mfa_required'] = 'true'
end

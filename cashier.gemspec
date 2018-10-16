# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'cashier/version'

Gem::Specification.new do |s|
  s.name        = 'cashier'
  s.version     = Cashier::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Adam Hawkins']
  s.email       = ['me@broadcastingadam.com']
  s.homepage    = 'https://github.com/threadedlabs/cashier'
  s.summary     = 'Tag based caching for Rails using Redis or Memcached'
  s.description = 'Associate different cached content with a tag, then expire by tag instead of key'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'dalli'
  s.add_development_dependency 'rails', '~> 5.2'
  s.add_development_dependency 'redis', '~> 4.0'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
end

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cashier/version"

Gem::Specification.new do |s|
  s.name        = "cashier"
  s.version     = Cashier::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Adam Hawkins"]
  s.email       = ["me@broadcastingadam.com"]
  s.homepage    = "https://github.com/threadedlabs/cashier"
  s.summary     = %q{Tag based caching for Rails using Redis or Memcached}
  s.description = %q{Associate different cached content with a tag, then expire by tag instead of key}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rails', '~> 4'
  s.add_dependency 'actionpack-action_caching'
  s.add_dependency 'actionpack-page_caching'

  s.add_development_dependency 'rspec', '~> 2.14.1'
  s.add_development_dependency 'rspec-rails', '~> 2.14.2'
  s.add_development_dependency 'dalli'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'redis', '~> 3.0'
end

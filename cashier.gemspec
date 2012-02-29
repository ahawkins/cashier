# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cashier/version"

Gem::Specification.new do |s|
  s.name        = "cashier"
  s.version     = Cashier::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Adam Hawkins"]
  s.email       = ["adman1965@gmail.com"]
  s.homepage    = "https://github.com/Adman65/cashier"
  s.summary     = %q{Tag based caching for Rails}
  s.description = %q{Associate different cached content with a tag, then expire by tag instead of key}

  s.rubyforge_project = "cashier"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rails'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'infinity_test'
  s.add_development_dependency 'dalli'
  s.add_development_dependency 'sqlite3'
end


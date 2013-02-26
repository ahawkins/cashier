require 'simplecov'
require 'redis'
require 'dalli'

SimpleCov.start

$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'cashier'

ENV['RAILS_ENV'] = 'test'
require 'dummy/config/environment'

require 'rspec/rails'

require 'fileutils'

RSpec.configure do |config|
  config.before(:suite) do
    Cashier::Adapters::RedisStore.redis = Redis.new :host => '127.0.0.1'
  end

  config.before(:each) do
    Cashier::Adapters::RedisStore.redis.flushdb
    Rails.cache.clear
  end
end

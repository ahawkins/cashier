# frozen_string_literal: true

require 'simplecov'
require 'redis'
require 'dalli'
require 'dummy/config/environment'
require 'rspec/rails'
require 'pry'
require 'fileutils'
require 'cashier'

SimpleCov.start

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

ENV['RAILS_ENV'] = 'test'

RSpec.configure do |config|
  config.before(:suite) do
    Cashier::Adapters::RedisStore.redis = Redis.new host: '127.0.0.1'
  end

  config.before do
    Cashier::Adapters::RedisStore.redis.flushdb
    Rails.cache.clear
  end
end

require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV['RAILS_ENV'] = 'test'
require 'dummy/config/environment'

require 'rspec/rails'

RSpec.configure do |config|
  config.before(:each) do
    Rails.cache.clear
  end
end

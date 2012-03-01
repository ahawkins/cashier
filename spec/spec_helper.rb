require 'simplecov'
require 'redis/connection/hiredis'
require 'redis'

SimpleCov.start

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV['RAILS_ENV'] = 'test'
require 'dummy/config/environment'

require 'rspec/rails'


RSpec.configure do |config|
  # ==========================> Redis test configuration
  REDIS_PID = "#{Rails.root}/tmp/pids/redis-test.pid"
  REDIS_CACHE_PATH = "#{Rails.root}/tmp/cache/"

  Dir.mkdir "#{Rails.root}/tmp" unless Dir.exists? "#{Rails.root}/tmp"
  Dir.mkdir "#{Rails.root}/tmp/pids" unless Dir.exists? "#{Rails.root}/tmp/pids"
  Dir.mkdir "#{Rails.root}/tmp/cache" unless Dir.exists? "#{Rails.root}/tmp/cache"

  config.before(:suite) do
    redis_options = {
      "daemonize"     => 'yes',
      "pidfile"       => REDIS_PID,
      "port"          => 9736,
      "timeout"       => 300,
      "save 900"      => 1,
      "save 300"      => 1,
      "save 60"       => 10000,
      "dbfilename"    => "dump.rdb",
      "dir"           => REDIS_CACHE_PATH,
      "loglevel"      => "debug",
      "logfile"       => "stdout",
      "databases"     => 16
    }.map { |k, v| "#{k} #{v}" }.join('\n')
    `echo '#{redis_options}' | redis-server -`
  end

  config.before(:each) do
    Rails.cache.clear
  end
end
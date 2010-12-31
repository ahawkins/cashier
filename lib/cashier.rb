# Cashier

module Cashier
  extend self

  # used to track all the tags Cashier is storing
  STORAGE_KEY = 'cashier-tags'

  # shamefully taken straight from Resque.
  # Thanks Defunkt :D

  # Accepts:
  #   1. A 'hostname:port' string
  #   2. A 'hostname:port:db' string (to select the Redis db)
  #   3. A 'hostname:port/namespace' string (to set the Redis namespace)
  #   4. A redis URL string 'redis://host:port'
  #   5. An instance of `Redis`, `Redis::Client`, `Redis::DistRedis`,
  #      or `Redis::Namespace`.
  def redis=(server)
    if server.respond_to? :split
      if server =~ /redis\:\/\//
        redis = Redis.connect(:url => server)
      else
        server, namespace = server.split('/', 2)
        host, port, db = server.split(':')
        redis = Redis.new(:host => host, :port => port,
          :thread_safe => true, :db => db)
      end
      namespace ||= :cashier

      @redis = Redis::Namespace.new(namespace, :redis => redis)
    elsif server.respond_to? :namespace=
        @redis = server
    else
      @redis = Redis::Namespace.new(:cashier, :redis => server)
    end
  end

  # Returns the current Redis connection. If none has been created, will
  # create a new one.
  def redis
    return @redis if @redis
    self.redis = 'localhost:6379'
    self.redis
  end

  def expire(*tags)
    tags.each do |tag|
      redis.smembers(tags).each do |cache_key|
        Rails.cache.delete(cache_key)
      end
      redis.del(tag)
      redis.srem(STORAGE_KEY, tag)
    end
  end

  def tags
    redis.smembers STORAGE_KEY
  end

  def wipe
    expire(*tags)
  end
end  

require 'cashier/controller_helper'

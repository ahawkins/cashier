module Cashier
  class StoreAdapters
    # Public: adapter which is used by cashier.
    #
    # Examples
    #
    #   Cashier.adapter
    #   # => Cashier::Adapters::CacheStore
    # 
    #   Cashier.adapter
    #   # => Cashier::Adapters::RedisStore
    #
    def self.current_adapter
      if @@adapter == :cache_store
        Cashier::Adapters::CacheStore
      else
        Cashier::Adapters::RedisStore
      end
    end

    # Public: set the adapter the Cashier module will use to store the keys
    #
    # cache_adapter - :cache_store / :redis_store
    #
    # Examples
    #
    #   Cashier.adapter = :redis_store
    #
    def self.adapter=(cache_adapter)
      @@adapter = cache_adapter
    end
  end
end

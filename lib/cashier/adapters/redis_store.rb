module Cashier
  module Adapters
    class RedisStore
      def self.redis
        @@redis
      end

      def self.redis=(redis_instance)
        @@redis = redis_instance
      end

      

      




    end
  end
end
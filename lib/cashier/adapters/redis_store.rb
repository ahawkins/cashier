module Cashier
  module Adapters
    class RedisStore
      def self.redis
        @@redis
      end

      def self.redis=(redis_instance)
        @@redis = redis_instance
      end

      def self.namespace
        @@namespace ||= []
      end

      def self.namespace=(prefix)
        @@namespace = Array(prefix)
      end

      def self.namespaced(key)
        [namespace, key].flatten.join(':')
      end

      def self.store_fragment_in_tag(fragment, tag)
        redis.sadd(namespaced(tag), fragment)
      end

      def self.store_tags(tags)
        tags.each { |tag| redis.sadd(namespaced(Cashier::CACHE_KEY), tag) }
      end

      def self.remove_tags(tags)
        tags.each { |tag| redis.srem(namespaced(Cashier::CACHE_KEY), tag) }
      end

      def self.tags
        redis.smembers(namespaced(Cashier::CACHE_KEY)) || []
      end

      def self.get_fragments_for_tag(tag)
        redis.smembers(namespaced(tag)) || []
      end

      def self.delete_tag(tag)
        redis.del(namespaced(tag))
      end

      def self.clear
        remove_tags(tags)
        redis.del(namespaced(Cashier::CACHE_KEY))
      end

      def self.keys
        tags.inject([]) { |arry, tag| arry += get_fragments_for_tag(tag) }.compact
      end
    end
  end
end

module Cashier
  module Adapters
    class RedisStore
      def self.redis
        @@redis
      end

      def self.redis=(redis_instance)
        @@redis = redis_instance
      end

      def self.store_fragment_in_tag(fragment, tag)
        redis.sadd(tag, fragment)
      end

      def self.store_tags(tags)
        tags.each { |tag| redis.sadd(Cashier::CACHE_KEY, tag) }
      end

      def self.remove_tags(tags)
        tags.each { |tag| redis.srem(Cashier::CACHE_KEY, tag) }
      end

      def self.tags
        redis.smembers(Cashier::CACHE_KEY) || []
      end

      def self.get_fragments_for_tag(tag)
        redis.smembers(tag) || []
      end

      def self.delete_tag(tag)
        redis.del(tag)
      end

      def self.clear
        remove_tags(tags)
        redis.del(Cashier::CACHE_KEY)
      end

      def self.keys
        tags.inject([]) { |arry, tag| arry += get_fragments_for_tag(tag) }.compact
      end

      def self.get_tags_containers(tags)
        all_containers = []
        cache_keys = tags.map { |tag| Cashier::container_cache_key(tag) }
        all_containers = redis.sunion(*cache_keys)        
        return all_containers
      end

      def self.add_tags_containers(tags, containers)
        return if !containers || containers.empty?
        tags.each do |tag|
          cache_key = Cashier::container_cache_key(tag)
          redis.sadd(cache_key, containers.flatten)
        end
      end

    end
  end
end

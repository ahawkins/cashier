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

      def self.store_path_in_tag(page_path, tag)
        redis.sadd(page_path_tag(tag), page_path)
      end

      def self.store_tags(tags)
        tags.each { |tag| redis.sadd(Cashier::CACHE_KEY, tag) }
      end

      def self.store_page_tags(tags)
        tags.each { |tag| redis.sadd(Cashier::CACHE_KEY, "page-path:" + tag)}
      end

      def self.remove_tags(tags)
        tags.each { |tag| redis.srem(Cashier::CACHE_KEY, tag) }
      end

      def self.remove_page_tags(tags)
        tags.each { |tag| redis.srem(Cashier::CACHE_KEY, "page-path:" + tag) }
      end

      def self.tags
        redis.smembers(Cashier::CACHE_KEY) || []
      end

      def self.get_fragments_for_tag(tag)
        redis.smembers(tag) || []
      end

      def self.get_page_paths_for_tag(tag)
        tag = page_path_tag(tag)
        redis.smembers(tag) || []
      end

      def self.delete_tag(tag)
        redis.del(tag)
      end

      def self.delete_path_tag(tag)
        redis.del(page_path_tag(tag))
      end

      def self.clear
        remove_tags(tags)
        redis.del(Cashier::CACHE_KEY)
      end

      def self.keys
        tags.inject([]) { |arry, tag| arry += get_fragments_for_tag(tag) }.compact
      end

      private

      def self.page_path_tag(tag)
        "page-path:" + tag
      end
    end
  end
end

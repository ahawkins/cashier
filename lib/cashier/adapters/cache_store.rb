module Cashier
  module Adapters
    class CacheStore
      def self.store_fragment_in_tag(fragment, tag)
        fragments = Rails.cache.fetch(tag) || []
        new_fragments = fragments + [fragment]
        Rails.cache.write(tag, new_fragments)
      end

      def self.store_tags(tags)

        cashier_tags = Rails.cache.fetch(Cashier::CACHE_KEY) || []
        cashier_tags = (cashier_tags + tags).uniq

        Rails.cache.write(Cashier::CACHE_KEY, cashier_tags)
      end

      def self.remove_tags(tags)
        cashier_tags = Rails.cache.fetch(Cashier::CACHE_KEY) || []
        cashier_tags = (cashier_tags - tags).uniq
        Rails.cache.write(Cashier::CACHE_KEY, cashier_tags)
      end

      def self.tags
        Rails.cache.read(Cashier::CACHE_KEY) || []
      end

      def self.get_fragments_for_tag(tag)
        Rails.cache.read(tag) || []
      end

      def self.delete_tag(tag)
        Rails.cache.delete(tag)  
      end

      def self.clear
        remove_tags(tags)
        Rails.cache.delete(Cashier::CACHE_KEY)
      end

      def self.keys
        tags.inject([]) { |arry, tag| arry += Rails.cache.fetch(tag) }.compact
      end

      def self.get_tags_containers(tags)
        all_containers = []
        tags.each do |tag|
          cache_key = Cashier::container_cache_key(tag)
          containers = Rails.cache.fetch(cache_key) || []
          all_containers += containers
        end
        return all_containers.flatten.uniq
      end

      def self.add_tags_containers(tags, containers)
        tags.each do |tag|
          cache_key = Cashier::container_cache_key(tag)
          existing_containers = Rails.cache.fetch(cache_key) || []
          all_containers = (existing_containers + containers).flatten.uniq
          Rails.cache.write(cache_key, all_containers)
        end
      end

    end
  end
end

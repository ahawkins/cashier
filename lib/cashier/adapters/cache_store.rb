module Cashier
  module Adapters
    class CacheStore
      def self.store_fragment_in_tag(tag, fragment)
        fragments = Rails.cache.fetch(tag) || []
        Rails.cache.write(tag, fragments + [fragment])
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
        Rails.cache.fetch(Cashier::CACHE_KEY) || []
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
      
    end
  end
end